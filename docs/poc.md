# Proof of Concept

The PoC project for ./systemc-compiler including:

* build systemc-compiler project on opensuse tumbleweed platform
* writing src/zoo.cpp example
* running src/zoo.cpp with Accellera SystemC
* compiling src/zoo.cpp -> Verilog rtl/zoo.sv
* running rtl/zoo.sv via Verilator
* writing C++ testbench src/tb.cpp for Verilated Vzoo/ project
* running simulation, dumping VCD trace

## Implementation Plan

### Phase 1: Environment Setup
1. **Platform Configuration**
   - Set up openSUSE Tumbleweed build environment
   - Install required dependencies (LLVM, Clang, CMake, SystemC libraries)
   - Configure build toolchain

2. **SystemC Compiler Build**
   - Clone systemc-compiler repository
   - Configure CMake build system
   - Build and install systemc-compiler
   - Verify installation and tool availability

3. **Example Verification**
   - Build all provided ICSC examples
   - Run SCTool on each example to generate Verilog
   - Lint all generated Verilog with Verilator
   - Verify SystemC-to-Verilog translation works correctly
   - Validate generated RTL quality and completeness
   - Generate consolidated lint reports grouped by warning type

### Phase 2: SystemC Development
4. **Example Design Creation**
   - Write `src/zoo.cpp` SystemC module
   - Implement basic functionality (counters, state machines, etc.)
   - Add appropriate headers and module structure
   - Document design intent

5. **SystemC Simulation**
   - Build with Accellera SystemC library
   - Create SystemC testbench
   - Run functional simulation
   - Verify expected behavior

### Phase 3: RTL Generation
6. **SystemC to Verilog Conversion**
   - Configure systemc-compiler for the project
   - Run compilation: `src/zoo.cpp` → `rtl/zoo.sv`
   - Review generated Verilog code
   - Verify structural equivalence

### Phase 4: Verilog Simulation
7. **Verilator Setup**
   - Install Verilator simulator
   - Configure Verilator build for generated RTL
   - Verilate `rtl/zoo.sv` to create C++ model

8. **C++ Testbench Development**
   - Write `src/tb.cpp` for Verilated module
   - Implement test scenarios
   - Add VCD trace generation
   - Set up clock and reset handling

9. **Simulation and Verification**
   - Compile and link testbench with Verilated model
   - Run simulation
   - Generate VCD waveform files
   - Analyze results with waveform viewer

### Phase 5: Validation
10. **Cross-Verification**
   - Compare SystemC simulation results with Verilog simulation
   - Verify timing and functional equivalence
   - Document any discrepancies

11. **Documentation**
    - Document build process
    - Create usage examples
    - Write troubleshooting guide

## Checklist

### Environment Setup
- [ ] openSUSE Tumbleweed installed/configured
- [ ] LLVM/Clang toolchain installed
- [ ] CMake installed (version 3.15+)
- [ ] Accellera SystemC library installed
- [ ] systemc-compiler cloned
- [ ] systemc-compiler built successfully
- [ ] systemc-compiler installed to system path
- [ ] Example designs built successfully (via `make_examples.sh`)
- [ ] Verilog generated from all examples
- [ ] Verilator lint executed on all generated RTL
- [ ] Generated RTL verified for quality (no errors, acceptable warnings)
- [ ] Consolidated lint report generated and reviewed

### SystemC Development
- [ ] `src/zoo.cpp` created
- [ ] SystemC module structure implemented
- [ ] Build system configured for SystemC
- [ ] SystemC simulation runs successfully
- [ ] Simulation results verified

### RTL Generation
- [ ] systemc-compiler configuration file created
- [ ] `src/zoo.cpp` compiled to Verilog
- [ ] `rtl/zoo.sv` generated successfully
- [ ] Generated Verilog reviewed for correctness
- [ ] RTL directory structure organized

### Verilog Simulation
- [ ] Verilator installed
- [ ] Verilator build configuration created
- [ ] `rtl/zoo.sv` verilated successfully
- [ ] Verilated C++ model generated (Vzoo/)
- [ ] `src/tb.cpp` testbench written
- [ ] Testbench compiled and linked
- [ ] VCD trace generation implemented
- [ ] Simulation runs successfully
- [ ] VCD files generated

### Verification & Documentation
- [ ] Waveforms inspected with viewer (GTKWave/etc.)
- [ ] SystemC vs. Verilog results compared
- [ ] Functional equivalence verified
- [ ] Build process documented
- [ ] Usage instructions written
- [ ] Known issues documented
- [ ] PoC completion report created

## Verification Tools and Methodology

### Phase 1 Verification Script

The `make_examples.sh` script provides comprehensive verification:

1. **Build Phase**: Compiles all 19 example designs with CMake
2. **Generation Phase**: Runs SCTool executables to generate SystemVerilog
3. **Linting Phase**: Runs Verilator lint on all generated `.sv` files
4. **Reporting Phase**: Creates consolidated reports grouped by warning type

### Lint Report Format

The consolidated report (`example_tests/build_all_examples/verilator_lint_report.txt`) contains:

- **Summary Section**: Warnings grouped by type with occurrence counts
- **Breakdown Section**: Files affected by each warning type with examples
- **Detailed Section**: Complete lint output for each file

See `docs/VERILATOR_REPORT_FORMAT.md` for detailed report structure.

### Documentation

Phase 1 completion is documented in:
- `docs/INSTALL_VERIFIED.md` - Installation verification results
- `docs/EXAMPLES_TEST_RESULTS.md` - Example build and test results
- `docs/VERILATOR_LINT_SUMMARY.md` - Verilator integration summary
- `docs/VERILATOR_REPORT_FORMAT.md` - Lint report structure
- `docs/CONSOLIDATION_SUMMARY.md` - Script consolidation details
- `docs/DEBUG_COMPLETE_SUMMARY.md` - Example debugging summary

## Success Criteria

### Phase 1 (Environment Setup) - ✅ COMPLETE
- ✅ SystemC compiler builds and installs correctly
- ✅ All 19 working examples build successfully (dvcon20 excluded due to upstream bug)
- ✅ SystemC-to-Verilog conversion completes without errors (19/19 examples)
- ✅ Generated Verilog is syntactically correct (0 lint errors)
- ✅ Verilator lint integration working with grouped reporting
- ✅ Installation automated and reproducible via `install.sh`

### Future Phases
- ⏳ SystemC design compiles and simulates correctly
- ⏳ Verilated simulation produces valid results
- ⏳ VCD traces show expected waveforms
- ⏳ Functional equivalence between SystemC and Verilog verified
- ⏳ Complete toolchain workflow demonstrated end-to-end
