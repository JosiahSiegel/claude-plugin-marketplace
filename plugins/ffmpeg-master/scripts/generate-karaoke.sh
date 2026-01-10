#!/bin/bash
# FFmpeg Karaoke & Kinetic Caption Generator Utility
# Generate ASS karaoke/kinetic subtitles and apply to video
# Usage: ./generate-karaoke.sh <action> [options]
#
# Actions: create, apply, template, kinetic

set -e

ACTION="${1:-help}"

show_help() {
    echo "FFmpeg Karaoke & Kinetic Caption Generator Utility"
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  create <lyrics.txt> <output.ass> [style]"
    echo "      Convert timestamped lyrics to ASS karaoke format"
    echo "      Styles: default, neon, outline, shadow, gradient"
    echo ""
    echo "  kinetic <lyrics.txt> <output.ass> [effect] [platform]"
    echo "      Create kinetic captions with animation effects"
    echo "      Effects: pop, grow, bounce, elastic, karaoke-grow"
    echo "      Platforms: tiktok, youtube, instagram (default: tiktok)"
    echo ""
    echo "  apply <video> <subtitles.ass> <output>"
    echo "      Burn ASS subtitles into video"
    echo ""
    echo "  template <style> <output.ass>"
    echo "      Generate ASS template file for manual editing"
    echo "      Styles: default, neon, outline, shadow, gradient, kinetic-pop,"
    echo "              kinetic-grow, kinetic-bounce, kinetic-elastic"
    echo ""
    echo "Lyrics format (lyrics.txt):"
    echo "  [MM:SS.ms] Line text here"
    echo "  [00:05.00] First line of song"
    echo "  [00:10.50] Second line continues"
    echo ""
    echo "Examples:"
    echo "  $0 create lyrics.txt karaoke.ass neon"
    echo "  $0 kinetic lyrics.txt kinetic.ass bounce tiktok"
    echo "  $0 apply video.mp4 karaoke.ass output.mp4"
    echo "  $0 template kinetic-pop template.ass"
}

get_style_header() {
    local style="$1"
    local header="[Script Info]
Title: Karaoke Subtitles
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
Timer: 100.0000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"

    case "$style" in
        neon)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FF00FF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,72,&H0000FFFF,&H00FF00FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,280,1"
            ;;
        outline)
            echo "$header"
            echo "Style: Default,Impact,80,&H00FFFFFF,&H00FFFF00,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,280,1"
            echo "Style: Karaoke,Impact,80,&H00FFFF00,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,280,1"
            ;;
        shadow)
            echo "$header"
            echo "Style: Default,Arial Black,68,&H00FFFFFF,&H0000FF00,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,68,&H0000FF00,&H00FFFFFF,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,280,1"
            ;;
        gradient)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FFFFFF,&H00FF8800,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,72,&H00FF8800,&H00FFFFFF,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            ;;
        *)
            echo "$header"
            echo "Style: Default,Arial,64,&H00FFFFFF,&H000088FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial,64,&H000088FF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            ;;
    esac
}

get_kinetic_header() {
    local platform="$1"
    local font_name="Arial Black"
    local font_size=88

    case "$platform" in
        youtube)
            font_name="Montserrat"
            font_size=76
            ;;
        instagram)
            font_name="Impact"
            font_size=82
            ;;
        tiktok|*)
            font_name="Arial Black"
            font_size=88
            ;;
    esac

    cat << EOF
[Script Info]
Title: Kinetic Captions
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
Timer: 100.0000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KineticPop,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticGrow,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticBounce,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticElastic,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1
Style: KaraokeGrow,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
EOF
}

get_kinetic_effect() {
    local effect="$1"
    local word="$2"

    case "$effect" in
        pop)
            # Word pops in: 50% → 115% → 100%
            echo "{\\fscx50\\fscy50\\t(0,100,\\fscx115\\fscy115)\\t(100,200,\\fscx100\\fscy100)}${word}"
            ;;
        grow)
            # Word grows: 80% → 115% → 100%
            echo "{\\fscx80\\fscy80\\t(0,150,\\fscx115\\fscy115)\\t(150,300,\\fscx100\\fscy100)}${word}"
            ;;
        bounce)
            # Spring bounce: 80% → 120% → 95% → 100%
            echo "{\\fscx80\\fscy80\\t(0,100,\\fscx120\\fscy120)\\t(100,200,\\fscx95\\fscy95)\\t(200,300,\\fscx100\\fscy100)}${word}"
            ;;
        elastic)
            # Elastic overshoot: 40% → 130% → 90% → 105% → 100%
            echo "{\\fscx40\\fscy40\\t(0,80,\\fscx130\\fscy130)\\t(80,160,\\fscx90\\fscy90)\\t(160,260,\\fscx105\\fscy105)\\t(260,380,\\fscx100\\fscy100)}${word}"
            ;;
        karaoke-grow)
            # Karaoke with grow effect (returns just animation, karaoke tag added separately)
            echo "\\t(0,150,\\fscx115\\fscy115)\\t(150,300,\\fscx100\\fscy100)"
            ;;
        *)
            echo "{\\fscx50\\fscy50\\t(0,100,\\fscx115\\fscy115)\\t(100,200,\\fscx100\\fscy100)}${word}"
            ;;
    esac
}

get_style_for_effect() {
    local effect="$1"
    case "$effect" in
        pop) echo "KineticPop" ;;
        grow) echo "KineticGrow" ;;
        bounce) echo "KineticBounce" ;;
        elastic) echo "KineticElastic" ;;
        karaoke-grow) echo "KaraokeGrow" ;;
        *) echo "KineticPop" ;;
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

create_kinetic() {
    local lyrics_file="$1"
    local output_file="$2"
    local effect="${3:-pop}"
    local platform="${4:-tiktok}"

    if [[ ! -f "$lyrics_file" ]]; then
        echo "Error: Lyrics file not found: $lyrics_file"
        exit 1
    fi

    echo "Creating kinetic captions from: $lyrics_file (effect: $effect, platform: $platform)"

    # Write header
    get_kinetic_header "$platform" > "$output_file"

    # Add events section
    echo "" >> "$output_file"
    echo "[Events]" >> "$output_file"
    echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" >> "$output_file"

    local style_name=$(get_style_for_effect "$effect")
    local prev_time=""
    local prev_text=""
    local line_num=0

    # Word display overlap in centiseconds (for smooth transition)
    local word_overlap=30

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Parse timestamp and text: [MM:SS.ms] Text
        if [[ "$line" =~ ^\[([0-9]+:[0-9]+\.[0-9]+)\]\ (.+)$ ]]; then
            local timestamp="${BASH_REMATCH[1]}"
            local text="${BASH_REMATCH[2]}"

            if [[ -n "$prev_time" && -n "$prev_text" ]]; then
                local start_ass=$(timestamp_to_ass "[$prev_time]")
                local end_ass=$(timestamp_to_ass "[$timestamp]")

                if [[ "$effect" == "karaoke-grow" ]]; then
                    # Karaoke with grow effect (line-based)
                    local karaoke_text=""
                    local grow_effect=$(get_kinetic_effect "$effect" "")
                    for word in $prev_text; do
                        karaoke_text="${karaoke_text}{\\k100${grow_effect}}${word} "
                    done
                    karaoke_text="${karaoke_text% }"
                    echo "Dialogue: 0,${start_ass},${end_ass},${style_name},,0,0,0,,${karaoke_text}" >> "$output_file"
                else
                    # Word-by-word kinetic effect
                    local words=($prev_text)
                    local word_count=${#words[@]}
                    local line_duration_cs=$(( ($(echo "$timestamp" | awk -F: '{print $1*60 + $2}' | tr -d '.') - $(echo "$prev_time" | awk -F: '{print $1*60 + $2}' | tr -d '.')) ))
                    local word_duration_cs=$((line_duration_cs / word_count))

                    # Parse start time components
                    local start_min="${prev_time%%:*}"
                    local start_rest="${prev_time#*:}"
                    local start_sec="${start_rest%.*}"
                    local start_ms="${start_rest#*.}"

                    local current_cs=$((start_min * 6000 + start_sec * 100 + ${start_ms:0:2}))

                    for word in "${words[@]}"; do
                        local word_start_min=$((current_cs / 6000))
                        local word_start_sec=$(((current_cs % 6000) / 100))
                        local word_start_cs=$((current_cs % 100))
                        local word_start=$(printf "0:%02d:%02d.%02d" "$word_start_min" "$word_start_sec" "$word_start_cs")

                        local word_end_cs=$((current_cs + word_duration_cs + word_overlap))
                        local word_end_min=$((word_end_cs / 6000))
                        local word_end_sec=$(((word_end_cs % 6000) / 100))
                        local word_end_csec=$((word_end_cs % 100))
                        local word_end=$(printf "0:%02d:%02d.%02d" "$word_end_min" "$word_end_sec" "$word_end_csec")

                        local kinetic_text=$(get_kinetic_effect "$effect" "$word")
                        echo "Dialogue: 0,${word_start},${word_end},${style_name},,0,0,0,,${kinetic_text}" >> "$output_file"

                        current_cs=$((current_cs + word_duration_cs))
                    done
                fi
            fi

            prev_time="$timestamp"
            prev_text="$text"
            ((line_num++))
        fi
    done < "$lyrics_file"

    # Handle last line
    if [[ -n "$prev_time" && -n "$prev_text" ]]; then
        local start_ass=$(timestamp_to_ass "[$prev_time]")
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

        if [[ "$effect" == "karaoke-grow" ]]; then
            local karaoke_text=""
            local grow_effect=$(get_kinetic_effect "$effect" "")
            for word in $prev_text; do
                karaoke_text="${karaoke_text}{\\k100${grow_effect}}${word} "
            done
            karaoke_text="${karaoke_text% }"
            echo "Dialogue: 0,${start_ass},${end_ass},${style_name},,0,0,0,,${karaoke_text}" >> "$output_file"
        else
            local words=($prev_text)
            local word_count=${#words[@]}
            local word_duration_cs=$((500 / word_count))

            local start_min="${prev_time%%:*}"
            local start_rest="${prev_time#*:}"
            local start_sec="${start_rest%.*}"
            local start_ms="${start_rest#*.}"

            local current_cs=$((start_min * 6000 + start_sec * 100 + ${start_ms:0:2}))

            for word in "${words[@]}"; do
                local word_start_min=$((current_cs / 6000))
                local word_start_sec=$(((current_cs % 6000) / 100))
                local word_start_csec=$((current_cs % 100))
                local word_start=$(printf "0:%02d:%02d.%02d" "$word_start_min" "$word_start_sec" "$word_start_csec")

                local word_end_cs=$((current_cs + word_duration_cs + 30))
                local word_end_min=$((word_end_cs / 6000))
                local word_end_sec=$(((word_end_cs % 6000) / 100))
                local word_end_csec=$((word_end_cs % 100))
                local word_end=$(printf "0:%02d:%02d.%02d" "$word_end_min" "$word_end_sec" "$word_end_csec")

                local kinetic_text=$(get_kinetic_effect "$effect" "$word")
                echo "Dialogue: 0,${word_start},${word_end},${style_name},,0,0,0,,${kinetic_text}" >> "$output_file"

                current_cs=$((current_cs + word_duration_cs))
            done
        fi
    fi

    echo "Created kinetic captions file: $output_file ($line_num lines, $effect effect)"
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

    case "$style" in
        kinetic-pop|kinetic-grow|kinetic-bounce|kinetic-elastic)
            local effect="${style#kinetic-}"
            get_kinetic_header "tiktok" > "$output"
            local style_name=$(get_style_for_effect "$effect")

            cat >> "$output" << EOF

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
; Kinetic Caption Template ($effect effect)
; Each word appears with $effect animation
; Timing: Start,End in H:MM:SS.CC format
;
; Example word-by-word kinetic captions:
EOF
            local example_words=("This" "is" "an" "example")
            local start_cs=500
            for word in "${example_words[@]}"; do
                local start_min=$((start_cs / 6000))
                local start_sec=$(((start_cs % 6000) / 100))
                local start_csec=$((start_cs % 100))
                local start=$(printf "0:%02d:%02d.%02d" "$start_min" "$start_sec" "$start_csec")

                local end_cs=$((start_cs + 80))
                local end_min=$((end_cs / 6000))
                local end_sec=$(((end_cs % 6000) / 100))
                local end_csec=$((end_cs % 100))
                local end=$(printf "0:%02d:%02d.%02d" "$end_min" "$end_sec" "$end_csec")

                local kinetic_text=$(get_kinetic_effect "$effect" "$word")
                echo "Dialogue: 0,${start},${end},${style_name},,0,0,0,,${kinetic_text}" >> "$output"

                start_cs=$((start_cs + 50))
            done
            ;;
        *)
            get_style_header "$style" > "$output"

            cat >> "$output" << EOF

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
; Add your karaoke lines below
; Format: Dialogue: 0,START,END,Karaoke,,0,0,0,,{\\k100}Word1 {\\k100}Word2
; \\k value is duration in centiseconds (100 = 1 second)
Dialogue: 0,0:00:05.00,0:00:10.00,Karaoke,,0,0,0,,{\\k50}This {\\k50}is {\\k50}an {\\k100}example {\\k100}line
EOF
            ;;
    esac

    echo "Template created: $output"
    echo "Edit the file to add your karaoke/kinetic timing."
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
    kinetic)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_kinetic "$2" "$3" "$4" "$5"
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
