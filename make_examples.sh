#!/bin/bash
# Build all ICSC examples and generate Verilog
# Combines build configuration and SCTool execution

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check ICSC_HOME is set
if [ -z "$ICSC_HOME" ]; then
    echo_error "ICSC_HOME is not set. Please run: source ./setenv.sh"
    exit 1
fi

echo_info "======================================================================"
echo_info "ICSC Example Build and Verilog Generation"
echo_info "======================================================================"
echo_info "ICSC_HOME: $ICSC_HOME"
echo ""

# Build directory
BUILD_DIR="example_tests/build_all_examples"
mkdir -p "$BUILD_DIR"

# Step 1: Configure and build all examples
echo_info "Step 1: Configuring and building examples..."
cd "$BUILD_DIR"

cmake "$ICSC_HOME/designs/examples" -DCMAKE_BUILD_TYPE=Release > cmake.log 2>&1
if [ $? -ne 0 ]; then
    echo_error "CMake configuration failed. Check cmake.log"
    tail -50 cmake.log
    exit 1
fi
echo_info "  ✓ CMake configuration complete"

NCPUS=$(nproc)
JOBS=$((NCPUS > 2 ? NCPUS - 2 : 1))
make -j${JOBS} > build.log 2>&1
if [ $? -ne 0 ]; then
    echo_error "Build failed. Check build.log"
    tail -50 build.log
    exit 1
fi
echo_info "  ✓ Build complete (${JOBS} parallel jobs)"

cd ../..

# Step 2: Run all _sctool executables to generate Verilog
echo ""
echo_info "Step 2: Generating Verilog from all examples..."
echo ""

SUCCESS=0
FAILED=0
VERILOG_COUNT=0

for sctool in "$BUILD_DIR"/*/*_sctool; do
    if [ -x "$sctool" ]; then
        dir=$(dirname "$sctool")
        name=$(basename "$sctool")
        example_name=$(basename "$dir")

        echo_info "Running: $example_name/$name"
        cd "$dir"

        if ./"$name" > sctool_output.log 2>&1; then
            # Check for generated Verilog
            if [ -d "sv_out" ]; then
                sv_count=$(find sv_out -name "*.sv" | wc -l)
                VERILOG_COUNT=$((VERILOG_COUNT + sv_count))
                echo_info "  ✓ SUCCESS - Generated $sv_count Verilog file(s)"
                SUCCESS=$((SUCCESS + 1))
            else
                echo_info "  ✓ Ran successfully (no sv_out directory)"
                SUCCESS=$((SUCCESS + 1))
            fi
        else
            echo_error "  ✗ FAILED"
            echo_error "    Last 10 lines of output:"
            tail -10 sctool_output.log | sed 's/^/    /'
            FAILED=$((FAILED + 1))
        fi

        cd - > /dev/null
    fi
done

echo ""
echo_info "======================================================================"
echo_info "Step 3: Linting generated Verilog with Verilator"
echo_info "======================================================================"

# Check if Verilator is available
if ! command -v verilator &> /dev/null; then
    echo_warn "⚠ Verilator not found - skipping lint phase"
    echo_warn "  Install verilator to enable RTL quality checks"
    LINT_SKIPPED=true
else
    echo_info "Running Verilator lint on all generated SystemVerilog files..."
    echo ""

    LINT_CLEAN=0
    LINT_WARNINGS=0
    LINT_ERRORS=0

    # Create consolidated lint report in project root (summary will be added later)
    LINT_REPORT="verilator_lint_report.txt"
    DETAILED_REPORT="${LINT_REPORT}.detailed"

    echo "================================================================================" > "$LINT_REPORT"
    echo "Verilator Lint Report" >> "$LINT_REPORT"
    echo "Generated: $(date)" >> "$LINT_REPORT"
    echo "================================================================================" >> "$LINT_REPORT"
    echo "" >> "$LINT_REPORT"

    # Start detailed report (will be appended after summary)
    echo "" > "$DETAILED_REPORT"

    # Find all unique .sv files
    SV_FILES=$(find "$BUILD_DIR" -name "*.sv" | sort -u)

    if [ -z "$SV_FILES" ]; then
        echo_warn "⚠ No .sv files found to lint"
        LINT_SKIPPED=true
    else
        # Temporarily disable exit on error for the lint loop
        # (verilator exits with non-zero on warnings)
        set +e

        for sv_file in $SV_FILES; do
            rel_path=$(echo "$sv_file" | sed "s|$BUILD_DIR/||")

            # Run verilator with lint-only (don't use -Wall to avoid warnings-as-errors)
            verilator --sv --lint-only "$sv_file" > "${sv_file}.lint.log" 2>&1
            lint_exit=$?

            # Count actual errors vs warnings (strip whitespace, newlines, and ensure numeric)
            error_count=$(grep -c "%Error:" "${sv_file}.lint.log" 2>/dev/null || echo "0")
            error_count=$(echo "$error_count" | tr -d '\n\r' | tr -d ' ')
            error_count=${error_count:-0}

            warning_count=$(grep -c "%Warning" "${sv_file}.lint.log" 2>/dev/null || echo "0")
            warning_count=$(echo "$warning_count" | tr -d '\n\r' | tr -d ' ')
            warning_count=${warning_count:-0}

            # Subtract the "Exiting due to" summary lines from error count
            # (both "error(s)" and "warning(s)" summaries use %Error: prefix)
            exit_messages=$(grep -c "%Error: Exiting due to" "${sv_file}.lint.log" 2>/dev/null || echo "0")
            exit_messages=$(echo "$exit_messages" | tr -d '\n\r' | tr -d ' ')
            exit_messages=${exit_messages:-0}
            error_count=$((error_count - exit_messages))

            # If we still have errors after removing the exit message, those are real errors
            # Otherwise check if it was just warnings causing the exit
            if [ "$error_count" -le 0 ] && [ "$warning_count" -gt 0 ]; then
                # No real errors, just warnings
                error_count=0
            fi

            # Add to detailed report (will be appended after summary)
            echo "================================================================================" >> "$DETAILED_REPORT"
            echo "File: $rel_path" >> "$DETAILED_REPORT"
            echo "================================================================================" >> "$DETAILED_REPORT"

            if [ "$error_count" -gt 0 ]; then
                echo_error "✗ $rel_path - $error_count error(s), $warning_count warning(s)"
                LINT_ERRORS=$((LINT_ERRORS + 1))
                # Show first few errors on console
                grep "%Error:" "${sv_file}.lint.log" | grep -v "Exiting due to" | head -2 | sed 's/^/    /'
                # Add all errors and warnings to detailed report
                echo "Status: ERRORS FOUND ($error_count error(s), $warning_count warning(s))" >> "$DETAILED_REPORT"
                echo "" >> "$DETAILED_REPORT"
                cat "${sv_file}.lint.log" >> "$DETAILED_REPORT"
            elif [ "$warning_count" -gt 0 ]; then
                echo_warn "⚠ $rel_path - $warning_count warning(s)"
                LINT_WARNINGS=$((LINT_WARNINGS + 1))
                # Add all warnings to detailed report
                echo "Status: WARNINGS ($warning_count warning(s))" >> "$DETAILED_REPORT"
                echo "" >> "$DETAILED_REPORT"
                cat "${sv_file}.lint.log" >> "$DETAILED_REPORT"
            else
                echo_info "✓ $rel_path - clean"
                LINT_CLEAN=$((LINT_CLEAN + 1))
                echo "Status: CLEAN" >> "$DETAILED_REPORT"
            fi

            echo "" >> "$DETAILED_REPORT"
        done

        # Re-enable exit on error
        set -e

        # Generate summary section grouped by warning type
        echo "" >> "$LINT_REPORT"
        echo "================================================================================" >> "$LINT_REPORT"
        echo "SUMMARY: Warnings Grouped by Type" >> "$LINT_REPORT"
        echo "================================================================================" >> "$LINT_REPORT"
        echo "" >> "$LINT_REPORT"

        # Extract and count all warning types
        if find "$BUILD_DIR" -name "*.lint.log" -exec cat {} \; 2>/dev/null | grep -q "%Warning"; then
            # Get all warning types and count them
            find "$BUILD_DIR" -name "*.lint.log" -exec grep "^%Warning-" {} \; 2>/dev/null | \
                sed 's/:.*//' | sort | uniq -c | sort -rn >> "$LINT_REPORT"

            echo "" >> "$LINT_REPORT"
            echo "Details by Warning Type:" >> "$LINT_REPORT"
            echo "" >> "$LINT_REPORT"

            # For each unique warning type, show which files have it
            for warning_type in $(find "$BUILD_DIR" -name "*.lint.log" -exec grep "^%Warning-" {} \; 2>/dev/null | \
                sed 's/:.*//' | sed 's/%Warning-//' | sort -u); do

                echo "--------------------------------------------------------------------------------" >> "$LINT_REPORT"
                echo "$warning_type" >> "$LINT_REPORT"
                echo "--------------------------------------------------------------------------------" >> "$LINT_REPORT"

                # Find all files with this warning type and show one example
                for lint_file in $(find "$BUILD_DIR" -name "*.lint.log" 2>/dev/null); do
                    if grep -q "^%Warning-$warning_type:" "$lint_file" 2>/dev/null; then
                        sv_file=$(echo "$lint_file" | sed 's/\.lint\.log$//')
                        rel_path=$(echo "$sv_file" | sed "s|$BUILD_DIR/||")
                        count=$(grep -c "^%Warning-$warning_type:" "$lint_file" 2>/dev/null)
                        echo "  • $rel_path ($count occurrence(s))" >> "$LINT_REPORT"
                    fi
                done

                # Show one example of this warning
                example=$(find "$BUILD_DIR" -name "*.lint.log" -exec grep -A3 "^%Warning-$warning_type:" {} \; 2>/dev/null | head -4)
                if [ -n "$example" ]; then
                    echo "" >> "$LINT_REPORT"
                    echo "  Example:" >> "$LINT_REPORT"
                    echo "$example" | sed 's/^/  /' >> "$LINT_REPORT"
                fi
                echo "" >> "$LINT_REPORT"
            done
        else
            echo "No warnings found!" >> "$LINT_REPORT"
        fi

        echo "" >> "$LINT_REPORT"
        echo "================================================================================" >> "$LINT_REPORT"
        echo "DETAILED RESULTS BY FILE" >> "$LINT_REPORT"
        echo "================================================================================" >> "$LINT_REPORT"
        echo "" >> "$LINT_REPORT"

        # Append the detailed per-file results
        DETAILED_REPORT="${LINT_REPORT}.detailed"
        if [ -f "$DETAILED_REPORT" ]; then
            cat "$DETAILED_REPORT" >> "$LINT_REPORT"
            rm "$DETAILED_REPORT"
        fi

        echo ""
        LINT_SKIPPED=false
    fi
fi

echo ""
echo_info "======================================================================"
echo_info "Summary"
echo_info "======================================================================"
echo_info "  Examples built and run: $((SUCCESS + FAILED))"
echo_info "  Success:                $SUCCESS"
echo_info "  Failed:                 $FAILED"
echo_info "  Total Verilog files:    $VERILOG_COUNT"
echo ""

if [ "$LINT_SKIPPED" != "true" ]; then
    echo_info "Verilator Lint Results:"
    echo_info "  Files linted:           $((LINT_CLEAN + LINT_WARNINGS + LINT_ERRORS))"
    echo_info "  Clean:                  $LINT_CLEAN"
    echo_info "  Warnings only:          $LINT_WARNINGS"
    echo_info "  Errors:                 $LINT_ERRORS"
    echo ""
    echo_info "Consolidated lint report saved to:"
    echo_info "  $LINT_REPORT"
    echo ""
fi

if [ $FAILED -eq 0 ]; then
    if [ "$LINT_SKIPPED" = "true" ] || [ $LINT_ERRORS -eq 0 ]; then
        echo_info "✅ All examples completed successfully!"
        if [ "$LINT_SKIPPED" != "true" ]; then
            if [ $LINT_ERRORS -eq 0 ] && [ $LINT_WARNINGS -eq 0 ]; then
                echo_info "✅ All generated Verilog is clean (no errors or warnings)!"
            elif [ $LINT_ERRORS -eq 0 ]; then
                echo_info "✅ Generated Verilog has no errors ($LINT_WARNINGS files with warnings)"
            fi
        fi
        echo_info ""
        echo_info "Generated Verilog files are in:"
        echo_info "  $BUILD_DIR/*/sv_out/*.sv"
        if [ "$LINT_SKIPPED" != "true" ] && [ $LINT_WARNINGS -gt 0 ]; then
            echo_info ""
            echo_info "Lint details available in:"
            echo_info "  $BUILD_DIR/*/sv_out/*.lint.log"
        fi
        echo ""
        exit 0
    else
        echo_error "❌ Examples built successfully but $LINT_ERRORS Verilog file(s) have lint errors"
        echo_warn "  Check *.lint.log files for details"
        echo ""
        exit 1
    fi
else
    echo_warn "⚠ Some examples failed. Check logs in:"
    echo_warn "  $BUILD_DIR/*/sctool_output.log"
    echo ""
    exit 1
fi
