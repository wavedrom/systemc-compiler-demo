# systemc-compiler-demo

Proof of Concept project demonstrating the complete SystemC-to-Verilog compilation and simulation workflow using Intel SystemC Compiler.

## Quick Start

### Prerequisites

Ensure SystemC environment variables are set:

```bash
# Example: Set up SystemC environment (adjust paths for your installation)
export SYSTEMC_HOME=/path/to/systemc
export SYSTEMC_INCLUDE=$SYSTEMC_HOME/include
export SYSTEMC_LIBDIR=$SYSTEMC_HOME/lib
```

### Phase 1: Environment Setup

Run the installation script to set up all dependencies and build the SystemC compiler:

```bash
./install.sh
```

This script will:
- Install system dependencies (LLVM, Clang, CMake, Verilator, etc.)
- Build Intel SystemC Compiler from `./systemc-compiler`
- Install everything to `./icsc_install`
- Create `setenv.sh` for environment configuration
- Verify the installation

**Note:** If you want to skip system package installation (dependencies already installed):

```bash
./install.sh --skip-deps
```

After installation, source the environment:

```bash
source ./setenv.sh
```

#### Verify Installation

Build all provided examples and generate Verilog:

```bash
source ./setenv.sh
./make_examples.sh
```

This will:
- Build all 19 example designs from `icsc_install/designs/examples/`
- Run SCTool to generate SystemVerilog RTL
- Lint all generated Verilog with Verilator
- Produce ~20 `.sv` files in `example_tests/build_all_examples/*/sv_out/`
- Generate consolidated lint report: `example_tests/build_all_examples/verilator_lint_report.txt`
- Verify that SystemC-to-Verilog translation works correctly

**Lint Results:**
- ✅ 0 errors (all Verilog is syntactically correct)
- ⚠️ ~168 warnings across 15 files (width mismatches, latches - expected from ICSC)
- ✅ 5 files completely clean

### Project Structure

```
systemc-compiler-demo/
├── systemc-compiler/    # Intel SystemC Compiler (submodule/clone)
├── src/                 # SystemC source files and testbenches
├── rtl/                 # Generated Verilog RTL
├── docs/                # Documentation including PoC implementation plan
├── icsc_install/        # Installation directory (created by install.sh)
├── install.sh           # Phase 1 installation script
└── setenv.sh            # Environment setup (created by install.sh)
```

## Documentation

### Main Documentation
- **[docs/poc.md](docs/poc.md)** - Complete implementation plan and checklist

### Phase 1 Verification Documentation
- **[docs/INSTALL_VERIFIED.md](docs/INSTALL_VERIFIED.md)** - Installation verification results
- **[docs/EXAMPLES_TEST_RESULTS.md](docs/EXAMPLES_TEST_RESULTS.md)** - Example build and test results
- **[docs/VERILATOR_LINT_SUMMARY.md](docs/VERILATOR_LINT_SUMMARY.md)** - Verilator lint integration
- **[docs/VERILATOR_REPORT_FORMAT.md](docs/VERILATOR_REPORT_FORMAT.md)** - Lint report structure
- **[docs/CONSOLIDATION_SUMMARY.md](docs/CONSOLIDATION_SUMMARY.md)** - Script consolidation
- **[docs/DEBUG_COMPLETE_SUMMARY.md](docs/DEBUG_COMPLETE_SUMMARY.md)** - Example debugging

1. **Phase 1: Environment Setup** ← `./install.sh`
2. **Phase 2: SystemC Development** - Write and simulate SystemC
3. **Phase 3: RTL Generation** - Convert SystemC to Verilog
4. **Phase 4: Verilog Simulation** - Verilator simulation with VCD traces
5. **Phase 5: Validation** - Cross-verification and documentation

## Requirements

- **OS**: openSUSE Tumbleweed (or Ubuntu/Debian with adaptations)
- **Tools**: Git, CMake 3.15+, GCC/G++, Make
- **SystemC**: Available via environment variables:
  - `SYSTEMC_HOME` - SystemC installation directory
  - `SYSTEMC_INCLUDE` - SystemC include directory
  - `SYSTEMC_LIBDIR` - SystemC library directory
- **Other Dependencies**: Installed automatically by `install.sh`

## Documentation

- [Implementation Plan and Checklist](docs/poc.md)
- [Intel SystemC Compiler Wiki](https://github.com/intel/systemc-compiler/wiki)
- [User Guide](systemc-compiler/doc/ug.pdf)
