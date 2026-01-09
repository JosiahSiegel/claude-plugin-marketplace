#!/bin/bash
# FFmpeg Karaoke Generator Utility
# Generate ASS karaoke subtitles and apply to video
# Usage: ./generate-karaoke.sh <action> [options]
#
# Actions: create, apply, template

set -e

ACTION="${1:-help}"

show_help() {
    echo "FFmpeg Karaoke Generator Utility"
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  create <lyrics.txt> <output.ass> [style]"
    echo "      Convert timestamped lyrics to ASS karaoke format"
    echo "      Styles: default, neon, outline, shadow"
    echo ""
    echo "  apply <video> <subtitles.ass> <output>"
    echo "      Burn ASS subtitles into video"
    echo ""
    echo "  template <style> <output.ass>"
    echo "      Generate ASS template file for manual editing"
    echo "      Styles: default, neon, outline, shadow, gradient"
    echo ""
    echo "Lyrics format (lyrics.txt):"
    echo "  [MM:SS.ms] Line text here"
    echo "  [00:05.00] First line of song"
    echo "  [00:10.50] Second line continues"
    echo ""
    echo "Examples:"
    echo "  $0 create lyrics.txt karaoke.ass neon"
    echo "  $0 apply video.mp4 karaoke.ass output.mp4"
    echo "  $0 template shadow template.ass"
}

get_style_header() {
    local style="$1"
    local header="[Script Info]
Title: Karaoke Subtitles
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
Timer: 100.0000

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"

    case "$style" in
        neon)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FF00FF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,80,1"
            echo "Style: Karaoke,Arial Black,72,&H0000FFFF,&H00FF00FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,80,1"
            ;;
        outline)
            echo "$header"
            echo "Style: Default,Impact,80,&H00FFFFFF,&H00FFFF00,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,80,1"
            echo "Style: Karaoke,Impact,80,&H00FFFF00,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,80,1"
            ;;
        shadow)
            echo "$header"
            echo "Style: Default,Arial Black,68,&H00FFFFFF,&H0000FF00,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,80,1"
            echo "Style: Karaoke,Arial Black,68,&H0000FF00,&H00FFFFFF,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,80,1"
            ;;
        gradient)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FFFFFF,&H00FF8800,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,80,1"
            echo "Style: Karaoke,Arial Black,72,&H00FF8800,&H00FFFFFF,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,80,1"
            ;;
        *)
            echo "$header"
            echo "Style: Default,Arial,64,&H00FFFFFF,&H000088FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,80,1"
            echo "Style: Karaoke,Arial,64,&H000088FF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,80,1"
            ;;
    esac
}

timestamp_to_ass() {
    # Convert [MM:SS.ms] to H:MM:SS.cs format
    local ts="$1"
    ts="${ts#[}"
    ts="${ts%]}"
    local min="${ts%%:*}"
    local rest="${ts#*:}"
    local sec="${rest%.*}"
    local ms="${rest#*.}"
    # Convert ms to centiseconds (2 digits)
    local cs="${ms:0:2}"
    printf "0:%02d:%02d.%02d" "$min" "$sec" "$cs"
}

create_karaoke() {
    local lyrics_file="$1"
    local output_file="$2"
    local style="${3:-default}"

    if [[ ! -f "$lyrics_file" ]]; then
        echo "Error: Lyrics file not found: $lyrics_file"
        exit 1
    fi

    echo "Creating karaoke ASS from: $lyrics_file (style: $style)"

    # Write header
    get_style_header "$style" > "$output_file"

    # Add events section
    echo "" >> "$output_file"
    echo "[Events]" >> "$output_file"
    echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" >> "$output_file"

    local prev_time=""
    local prev_text=""
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Parse timestamp and text: [MM:SS.ms] Text
        if [[ "$line" =~ ^\[([0-9]+:[0-9]+\.[0-9]+)\]\ (.+)$ ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            local text="${BASH_REMATCH[2]}"

            # If we have a previous line, write it with calculated end time
            if [[ -n "$prev_time" && -n "$prev_text" ]]; then
                local start_ass=$(timestamp_to_ass "[$prev_time]")
                local end_ass=$(timestamp_to_ass "[$timestamp]")

                # Calculate karaoke timing (estimate ~100cs per word)
                local word_count=$(echo "$prev_text" | wc -w)
                local duration_per_word=100
                local karaoke_text=""

                for word in $prev_text; do
                    karaoke_text="${karaoke_text}{\\k${duration_per_word}}${word} "
                done
                karaoke_text="${karaoke_text% }"

                echo "Dialogue: 0,${start_ass},${end_ass},Karaoke,,0,0,0,,${karaoke_text}" >> "$output_file"
            fi

            prev_time="$timestamp"
            prev_text="$text"
            ((line_num++))
        fi
    done < "$lyrics_file"

    # Write the last line (add 5 seconds as end time)
    if [[ -n "$prev_time" && -n "$prev_text" ]]; then
        local start_ass=$(timestamp_to_ass "[$prev_time]")
        # Add 5 seconds to last timestamp for end time
        local min="${prev_time%%:*}"
        local rest="${prev_time#*:}"
        local sec="${rest%.*}"
        local ms="${rest#*.}"
        sec=$((sec + 5))
        if [[ $sec -ge 60 ]]; then
            sec=$((sec - 60))
            min=$((min + 1))
        fi
        local end_time=$(printf "%02d:%02d.%s" "$min" "$sec" "$ms")
        local end_ass=$(timestamp_to_ass "[$end_time]")

        local karaoke_text=""
        for word in $prev_text; do
            karaoke_text="${karaoke_text}{\\k100}${word} "
        done
        karaoke_text="${karaoke_text% }"

        echo "Dialogue: 0,${start_ass},${end_ass},Karaoke,,0,0,0,,${karaoke_text}" >> "$output_file"
    fi

    echo "Created karaoke file: $output_file ($line_num lines)"
}

apply_karaoke() {
    local video="$1"
    local subtitles="$2"
    local output="$3"

    if [[ ! -f "$video" ]]; then
        echo "Error: Video file not found: $video"
        exit 1
    fi

    if [[ ! -f "$subtitles" ]]; then
        echo "Error: Subtitle file not found: $subtitles"
        exit 1
    fi

    echo "Burning karaoke subtitles into video..."

    # Escape special characters in path for FFmpeg filter
    local escaped_subs="${subtitles//:/\\:}"
    escaped_subs="${escaped_subs//\\/\\\\}"

    ffmpeg -i "$video" \
        -vf "ass='${escaped_subs}'" \
        -c:v libx264 -crf 18 -preset medium \
        -c:a copy "$output"

    echo "Done! Output saved to: $output"
}

create_template() {
    local style="${1:-default}"
    local output="$2"

    echo "Creating ASS template (style: $style)..."

    get_style_header "$style" > "$output"

    echo "" >> "$output"
    echo "[Events]" >> "$output"
    echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" >> "$output"
    echo "; Add your karaoke lines below" >> "$output"
    echo "; Format: Dialogue: 0,START,END,Karaoke,,0,0,0,,{\\k100}Word1 {\\k100}Word2" >> "$output"
    echo "; \\k value is duration in centiseconds (100 = 1 second)" >> "$output"
    echo "Dialogue: 0,0:00:05.00,0:00:10.00,Karaoke,,0,0,0,,{\\k50}This {\\k50}is {\\k50}an {\\k100}example {\\k100}line" >> "$output"

    echo "Template created: $output"
    echo "Edit the file to add your karaoke timing."
}

# Main execution
case "$ACTION" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    create)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_karaoke "$2" "$3" "$4"
        ;;
    apply)
        [[ -z "$2" || -z "$3" || -z "$4" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        apply_karaoke "$2" "$3" "$4"
        ;;
    template)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_template "$2" "$3"
        ;;
    *)
        echo "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac
