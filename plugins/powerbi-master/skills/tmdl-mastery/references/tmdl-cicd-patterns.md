# TMDL CI/CD, Git Integration, and Deployment Patterns

## TMDL in Power BI Desktop (PBIP)

### Enabling TMDL Format

1. File > Options and settings > Options > Preview features
2. Check "Store semantic model using TMDL format"
3. Save As > Power BI Project (.pbip)

The semantic model is saved as a `definition/` folder inside the semantic model folder, replacing the monolithic `model.bim` file.

### PBIP Project Structure with TMDL

```
MyReport.pbip
MyReport.report/
    definition.pbir
    report.json
    pages/
        ...
MyReport.SemanticModel/
    definition.pbism            # Required -- specifies model format
    diagramLayout.json
    .pbi/
        localSettings.json      # Git-ignored (user-specific)
        editorSettings.json     # Shared editor settings
        cache.abf               # Git-ignored (local data cache)
    definition/                 # TMDL folder (replaces model.bim)
        database.tmdl
        model.tmdl
        relationships.tmdl
        expressions.tmdl
        tables/
            Sales.tmdl
            Product.tmdl
            Calendar.tmdl
        roles/
            RegionalManager.tmdl
        cultures/
            en-US.tmdl
        perspectives/
            SalesView.tmdl
    DAXQueries/                 # DAX query view saved tabs
        Analysis.dax
    TMDLScripts/                # TMDL view saved script tabs
        CalcGroup.tmdl
```

### Converting BIM to TMDL

**Via Power BI Desktop:**
1. Open existing PBIP project
2. Enable TMDL preview feature
3. Save -- Desktop prompts to upgrade
4. Select "Upgrade" (one-way conversion; BIM is deleted)

**Via Tabular Editor 2/3:**
1. File > Preferences > Serialization > "TMDL" mode
2. Open existing .bim file
3. File > Save to Folder -- outputs TMDL folder

**Via C# / TmdlSerializer:**
```csharp
// Load BIM file
var db = JsonSerializer.DeserializeDatabase(File.ReadAllText("model.bim"));

// Export as TMDL folder
TmdlSerializer.SerializeDatabaseToFolder(db, @"C:\output\definition");
```

### External Editing of TMDL Files

Install the VS Code TMDL extension for syntax highlighting, autocomplete, and diagnostics:
- Extension: "TMDL" by Microsoft (marketplace ID: `analysis-services.TMDL`)
- Newer alternative: "TMDL Language Support" (marketplace ID: `CPIM.TMDL-language-support`) -- adds DAX/M semantic highlighting, code actions, and formatting

**Important:** Power BI Desktop does not detect external file changes. Restart Desktop after editing TMDL files externally.

### TMDL View in Power BI Desktop

The TMDL view provides an integrated code editor for scripting semantic model changes:

- Drag objects from Data pane onto the TMDL view editor
- Right-click objects and select "Script TMDL"
- Edit with autocomplete, semantic highlighting, error diagnostics
- Preview changes before applying (side-by-side diff view)
- Apply changes via the Apply button (metadata only -- no data refresh)
- Script tabs are saved in TMDLScripts/ folder for PBIP projects

**Key capabilities:**
- Create calculation groups, perspectives, translations (objects without Desktop UI)
- Bulk rename using find-and-replace with regex
- Switch storage modes by modifying partition definitions
- Back up/restore semantic model metadata via saved scripts

## Git Integration Patterns

### .gitignore for PBIP with TMDL

```gitignore
# Power BI local cache and settings
**/.pbi/localSettings.json
**/.pbi/cache.abf

# Optional: exclude unapplied Power Query changes
# **/.pbi/unappliedChanges.json

# Build artifacts
**/bin/
**/obj/
*.user
```

### Branch Strategy for Power BI Teams

```
main (protected)
  |
  +-- dev (integration branch, connected to Dev Fabric workspace)
       |
       +-- feature/add-yoy-measures     (developer 1)
       +-- feature/update-product-table  (developer 2)
       +-- feature/new-rls-role          (developer 3)
```

**Workflow:**
1. Developer creates feature branch from `dev`
2. Makes changes in Desktop (PBIP/TMDL) or directly edits TMDL files
3. Commits and pushes to feature branch
4. Creates Pull Request to `dev`
5. CI pipeline validates TMDL (syntax, BPA rules)
6. Reviewer inspects TMDL diffs (granular per-file changes)
7. Merge to `dev` triggers sync to Dev workspace via Fabric Git
8. Promote `dev` to `main` via PR for production deployment

### Merge Conflict Resolution

TMDL's file-per-object structure minimizes conflicts. When they occur:

**Common conflict: model.tmdl ref ordering**
```
<<<<<<< HEAD
ref table Sales
ref table Product
ref table NewTableA
=======
ref table Sales
ref table Product
ref table NewTableB
>>>>>>> feature/branch
```
Resolution: Include both ref lines. Order matters for deterministic roundtrips but does not affect functionality.

**Common conflict: Same measure edited by two developers**
Since all measures for a table live in one file (tables/Sales.tmdl), conflicts can happen when two developers edit different measures in the same table. Resolution: Use standard three-way merge; each measure is a distinct block separated by blank lines.

**Prevention strategy:** Assign table ownership per developer when possible. Use partial declarations to split measures into separate files if needed.

## CI/CD with Azure DevOps

### Pipeline: Validate TMDL with Tabular Editor BPA

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - dev
  paths:
    include:
      - '*.SemanticModel/**'

pr:
  branches:
    include:
      - main
      - dev

pool:
  vmImage: 'windows-latest'

jobs:
- job: Validate_Semantic_Models
  displayName: 'Validate Semantic Models (TMDL)'
  steps:

  - task: PowerShell@2
    displayName: 'Download Tabular Editor CLI'
    inputs:
      targetType: 'inline'
      script: |
        $teUrl = "https://github.com/TabularEditor/TabularEditor/releases/latest/download/TabularEditor.Portable.zip"
        Invoke-WebRequest -Uri $teUrl -OutFile "TabularEditor.zip"
        Expand-Archive -Path "TabularEditor.zip" -DestinationPath "$(Agent.ToolsDirectory)/TabularEditor"

  - task: PowerShell@2
    displayName: 'Download BPA Rules'
    inputs:
      targetType: 'inline'
      script: |
        $rulesUrl = "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/BestPracticeRules/BPARules.json"
        Invoke-WebRequest -Uri $rulesUrl -OutFile "$(Agent.ToolsDirectory)/BPARules.json"

  - task: PowerShell@2
    displayName: 'Run BPA on all semantic models'
    inputs:
      targetType: 'inline'
      script: |
        $tePath = "$(Agent.ToolsDirectory)/TabularEditor/TabularEditor.exe"
        $rulesPath = "$(Agent.ToolsDirectory)/BPARules.json"
        $exitCode = 0

        Get-ChildItem -Path "$(Build.SourcesDirectory)" -Filter "definition" -Directory -Recurse | ForEach-Object {
            $modelPath = $_.FullName
            Write-Host "Validating: $modelPath"

            & $tePath $modelPath -A $rulesPath -V
            if ($LASTEXITCODE -ne 0) { $exitCode = 1 }
        }

        exit $exitCode
```

### Pipeline: Deploy TMDL to Power BI via XMLA

```yaml
# deploy-pipeline.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - '*.SemanticModel/**'

pool:
  vmImage: 'windows-latest'

variables:
  - group: PowerBI-ServicePrincipal  # Contains clientId, clientSecret, tenantId
  - name: workspaceXmla
    value: 'powerbi://api.powerbi.com/v1.0/myorg/Production-Workspace'
  - name: datasetName
    value: 'AdventureWorks'

jobs:
- job: Deploy_Semantic_Model
  displayName: 'Deploy TMDL to Power BI'
  steps:

  - task: PowerShell@2
    displayName: 'Install AMO NuGet Package'
    inputs:
      targetType: 'inline'
      script: |
        Register-PackageSource -Name NuGet -Location https://api.nuget.org/v3/index.json -ProviderName NuGet -Force
        Install-Package Microsoft.AnalysisServices.NetCore.retail.amd64 -Source NuGet -Destination "$(Agent.ToolsDirectory)/nuget" -Force -SkipDependencies

  - task: PowerShell@2
    displayName: 'Deploy TMDL to XMLA endpoint'
    inputs:
      targetType: 'inline'
      script: |
        $nugetPath = "$(Agent.ToolsDirectory)/nuget"
        $amoPath = Get-ChildItem -Path $nugetPath -Filter "Microsoft.AnalysisServices.Core.dll" -Recurse | Select-Object -First 1
        $tabPath = Get-ChildItem -Path $nugetPath -Filter "Microsoft.AnalysisServices.Tabular.dll" -Recurse | Select-Object -First 1

        [System.Reflection.Assembly]::LoadFrom($amoPath.FullName) | Out-Null
        [System.Reflection.Assembly]::LoadFrom($tabPath.FullName) | Out-Null

        $tmdlPath = Get-ChildItem -Path "$(Build.SourcesDirectory)" -Filter "definition" -Directory -Recurse | Select-Object -First 1

        Write-Host "Deserializing TMDL from: $($tmdlPath.FullName)"
        $model = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeModelFromFolder($tmdlPath.FullName)

        $connStr = "DataSource=$(workspaceXmla);User ID=app:$(clientId)@$(tenantId);Password=$(clientSecret)"
        $server = New-Object Microsoft.AnalysisServices.Tabular.Server
        $server.Connect($connStr)

        $db = $server.Databases["$(datasetName)"]
        $model.CopyTo($db.Model)
        $db.Model.SaveChanges()
        $server.Disconnect()

        Write-Host "Deployment complete."
    env:
      clientId: $(clientId)
      clientSecret: $(clientSecret)
      tenantId: $(tenantId)
```

## CI/CD with GitHub Actions

### Validate TMDL with Tabular Editor

```yaml
# .github/workflows/validate-tmdl.yml
name: Validate Semantic Models

on:
  pull_request:
    paths:
      - '**.SemanticModel/**'
  push:
    branches: [main, dev]
    paths:
      - '**.SemanticModel/**'

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download Tabular Editor
        shell: pwsh
        run: |
          $url = "https://github.com/TabularEditor/TabularEditor/releases/latest/download/TabularEditor.Portable.zip"
          Invoke-WebRequest -Uri $url -OutFile TabularEditor.zip
          Expand-Archive TabularEditor.zip -DestinationPath ./te

      - name: Download BPA Rules
        shell: pwsh
        run: |
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/BestPracticeRules/BPARules.json" -OutFile BPARules.json

      - name: Run Best Practice Analyzer
        shell: pwsh
        run: |
          $exitCode = 0
          Get-ChildItem -Path . -Filter "definition" -Directory -Recurse | ForEach-Object {
              Write-Host "Checking: $($_.FullName)"
              & ./te/TabularEditor.exe $_.FullName -A BPARules.json -V
              if ($LASTEXITCODE -ne 0) { $exitCode = 1 }
          }
          exit $exitCode
```

### Deploy TMDL via Tabular Editor CLI

```yaml
# .github/workflows/deploy-tmdl.yml
name: Deploy Semantic Model

on:
  push:
    branches: [main]
    paths:
      - '**.SemanticModel/**'

jobs:
  deploy:
    runs-on: windows-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Download Tabular Editor 2
        shell: pwsh
        run: |
          $url = "https://github.com/TabularEditor/TabularEditor/releases/latest/download/TabularEditor.Portable.zip"
          Invoke-WebRequest -Uri $url -OutFile TabularEditor.zip
          Expand-Archive TabularEditor.zip -DestinationPath ./te

      - name: Deploy to Power BI
        shell: pwsh
        env:
          PBI_CLIENT_ID: ${{ secrets.PBI_CLIENT_ID }}
          PBI_CLIENT_SECRET: ${{ secrets.PBI_CLIENT_SECRET }}
          PBI_TENANT_ID: ${{ secrets.PBI_TENANT_ID }}
          PBI_WORKSPACE_XMLA: ${{ vars.PBI_WORKSPACE_XMLA }}
          PBI_DATASET_NAME: ${{ vars.PBI_DATASET_NAME }}
        run: |
          $tmdlPath = Get-ChildItem -Path . -Filter "definition" -Directory -Recurse | Select-Object -First 1
          $connStr = "Provider=MSOLAP;DataSource=$env:PBI_WORKSPACE_XMLA;User ID=app:$env:PBI_CLIENT_ID@$env:PBI_TENANT_ID;Password=$env:PBI_CLIENT_SECRET;Initial Catalog=$env:PBI_DATASET_NAME"
          & ./te/TabularEditor.exe $tmdlPath.FullName -D $connStr "$env:PBI_DATASET_NAME"
```

## Fabric Git Integration with TMDL

### Connecting Fabric Workspace to Git

1. Open Fabric workspace > Settings > Git integration
2. Connect to Azure DevOps repo or GitHub repo
3. Select branch and folder
4. Fabric exports all workspace items including semantic models as TMDL

### Fabric Git Workflow

```
Fabric Workspace (Dev)  <--->  Azure DevOps / GitHub (dev branch)
         |
         | (PR + pipeline validation)
         v
Fabric Workspace (Prod) <--->  Azure DevOps / GitHub (main branch)
```

**Developer using Desktop:**
1. Clone repo locally
2. Open .pbip in Power BI Desktop
3. Edit semantic model (changes saved as TMDL)
4. Commit and push to feature branch
5. Create PR -- pipeline validates
6. Merge to dev -- Fabric syncs automatically

**Developer using Fabric Service:**
1. Create branch from workspace
2. Edit semantic model in Service (TMDL view or web editor)
3. Commit from workspace to branch
4. Create PR -- pipeline validates
5. Merge to dev -- workspace updates

### Tabular Editor 3 with Fabric Git

Tabular Editor 3 can connect directly to TMDL folders in a cloned repo:
1. File > Open > From Folder > select `definition/` folder
2. Edit model (DAX, tables, relationships)
3. Save (writes TMDL files back to disk)
4. Commit and push via Git

## Deployment Patterns

### Pattern 1: TMDL Source + XMLA Deploy (Recommended)

```
TMDL files (Git) --> TmdlSerializer.Deserialize --> TOM Model --> XMLA endpoint
```

Best for teams using Premium/Fabric capacity with XMLA read-write enabled.

### Pattern 2: TMDL Source + Tabular Editor CLI Deploy

```
TMDL files (Git) --> TabularEditor.exe -D <connection> --> XMLA endpoint
```

Simplest approach using Tabular Editor 2 (free). No custom code needed.

### Pattern 3: TMDL Source + Convert to BIM + Deploy

```
TMDL files --> TmdlSerializer --> JsonSerializer --> model.bim --> Deploy via TMSL/REST
```

Useful when deployment tooling only accepts BIM format.

**PowerShell conversion script:**
```powershell
param(
    [string]$TmdlFolderPath,
    [string]$BimFilePath
)

# Install NuGet package
$pkg = Install-Package Microsoft.AnalysisServices.NetCore.retail.amd64 -Source NuGet -Destination ./nuget -Force -SkipDependencies
$dllPath = Get-ChildItem -Path ./nuget -Filter "Microsoft.AnalysisServices.Tabular.dll" -Recurse | Select-Object -First 1

Add-Type -Path $dllPath.FullName

$db = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder($TmdlFolderPath)

$options = New-Object Microsoft.AnalysisServices.Tabular.SerializeOptions
$options.SplitMultilineStrings = $true

$bimContent = [Microsoft.AnalysisServices.Tabular.JsonSerializer]::SerializeDatabase($db, $options)

Set-Content -Path $BimFilePath -Value $bimContent -Encoding UTF8

Write-Host "Converted TMDL to BIM: $BimFilePath"
```

### Pattern 4: Fabric Deployment Pipelines

Use Fabric's built-in deployment pipelines for promotion across environments without custom CI/CD:

```
Dev Workspace --> Test Workspace --> Production Workspace
    (linked to dev branch)  (linked to test branch)  (linked to main branch)
```

Fabric deployment pipelines handle semantic model deployment natively, including dataset refresh rules and parameter binding.

## TmdlSerializer Complete API Reference

### Namespace and Package

```csharp
using Microsoft.AnalysisServices.Tabular;
// NuGet: Microsoft.AnalysisServices.NetCore.retail.amd64
// Minimum version: 19.61+ (TMDL support)
```

### Folder Serialization

```csharp
// Serialize TOM database to TMDL folder
TmdlSerializer.SerializeDatabaseToFolder(Database database, string path);

// Deserialize TMDL folder to TOM database
Database db = TmdlSerializer.DeserializeDatabaseFromFolder(string path);

// Deserialize TMDL folder to TOM model (without database wrapper)
Model model = TmdlSerializer.DeserializeModelFromFolder(string path);
```

### String Serialization

```csharp
// Serialize any TOM object to TMDL text
string tmdl = TmdlSerializer.SerializeObject(MetadataObject obj, bool qualifyObject = true);
```

`qualifyObject: true` includes parent ref declarations (e.g., `ref table Sales` before column definition).

### Compressed File Serialization

```csharp
// Serialize to compressed file (.tmdl.zip)
TmdlSerializer.SerializeModelToCompressedFile(Model model, string path);

// Deserialize from compressed file
Model model = TmdlSerializer.DeserializeModelFromCompressedFile(string path);
```

### Stream Serialization

```csharp
// Serialize model to stream documents
foreach (MetadataDocument doc in model.ToTmdl())
{
    using (TextWriter writer = new StreamWriter($"output/{doc.ObjectType}.tmdl"))
    {
        doc.WriteTo(writer);
    }
}

// Deserialize from streams (selective loading)
var context = MetadataSerializationContext.Create(MetadataSerializationStyle.Tmdl);

foreach (var file in Directory.GetFiles(tmdlPath, "*.tmdl", SearchOption.AllDirectories))
{
    if (file.Contains("/roles/")) continue;  // Skip roles
    using (TextReader reader = File.OpenText(file))
    {
        context.ReadFromDocument(file, reader);
    }
}

Model model = context.ToModel();
```

### Error Handling

```csharp
try
{
    var db = TmdlSerializer.DeserializeDatabaseFromFolder(tmdlPath);
}
catch (TmdlFormatException ex)
{
    // Invalid TMDL syntax (bad keyword, wrong indentation)
    Console.WriteLine($"Syntax error in '{ex.Document}' at line {ex.Line}: {ex.Message}");
    Console.WriteLine($"Line text: {ex.LineText}");
}
catch (TmdlSerializationException ex)
{
    // Valid syntax but invalid TOM metadata (type mismatch, missing required property)
    Console.WriteLine($"Metadata error in '{ex.Document}' at line {ex.Line}: {ex.Message}");
}
```

## Python Integration

Python can invoke TMDL operations via `pythonnet` or by calling Tabular Editor CLI:

### Using pythonnet (CLR)

```python
import clr
clr.AddReference("Microsoft.AnalysisServices.Tabular")
from Microsoft.AnalysisServices.Tabular import TmdlSerializer, Server

# Deserialize TMDL
model = TmdlSerializer.DeserializeModelFromFolder("./definition")

# Deploy
server = Server()
server.Connect("powerbi://api.powerbi.com/v1.0/myorg/Workspace")
db = server.Databases["MyDataset"]
model.CopyTo(db.Model)
db.Model.SaveChanges()
server.Disconnect()
```

### Using Tabular Editor CLI from Python

```python
import subprocess

result = subprocess.run([
    "./te/TabularEditor.exe",
    "./definition",
    "-D", "Provider=MSOLAP;DataSource=powerbi://...;User ID=app:client@tenant;Password=secret",
    "MyDataset"
], capture_output=True, text=True)

print(result.stdout)
if result.returncode != 0:
    print(f"Error: {result.stderr}")
```

## Common Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `TmdlFormatException: Invalid indentation` | Mixed tabs and spaces | Use tabs only (TMDL default) |
| Desktop shows error on open after external edit | Invalid TMDL syntax | Check error message for file/line; fix in VS Code |
| Desktop does not reflect external TMDL changes | Desktop does not hot-reload | Restart Power BI Desktop after external edits |
| `model.bim` and `definition/` both present | Ambiguous format | Delete one; PBIP v4.0+ prefers `definition/` folder |
| Merge conflict in model.tmdl | Competing ref line additions | Include all ref lines; order is cosmetic |
| BPA rules fail on TMDL folder | Tabular Editor version too old | Use Tabular Editor 2.17+ or TE3 for TMDL support |
| Deployment fails with auth error | Service principal not configured | Ensure app registration has dataset read/write + workspace admin |
| TMDL files not appearing in Fabric Git | Workspace not synced | Commit from workspace; or trigger manual sync |
| Annotations lost on roundtrip | Property not in TOM | Only TOM-supported properties serialize; custom metadata use annotations |
| `lineageTag` conflicts | Auto-generated GUIDs differ | Accept either side; lineageTags are for tracking, not functionality |
