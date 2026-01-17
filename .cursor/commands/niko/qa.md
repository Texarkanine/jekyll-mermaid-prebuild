# QA Command - Technical Validation

This command performs comprehensive technical validation to ensure all prerequisites are met before implementation. It validates dependencies, configuration, environment, and build functionality, and serves as a gatekeeper before BUILD mode.

**CRITICAL**: This command blocks BUILD mode until validation passes. QA validation must be completed after CREATIVE phase and before BUILD phase.

## Memory Bank Integration

Reads from:
- `memory-bank/tasks.md` - Task requirements and complexity level
- `memory-bank/creative/creative-*.md` - Design decisions (Level 3-4)
- `memory-bank/activeContext.md` - Current project context
- `memory-bank/progress.md` - Current implementation status

Creates:
- `memory-bank/.qa_validation_status` - Validation status file (PASS/FAIL)

Updates:
- `memory-bank/tasks.md` - Records validation results
- `memory-bank/progress.md` - Validation outcomes

## Progressive Rule Loading

### Step 1: Load Core Rules
```
Load: .cursor/rules/shared/niko/main.mdc
Load: .cursor/rules/shared/niko/Core/memory-bank-paths.mdc
Load: .cursor/rules/shared/niko/Core/command-execution.mdc
```

### Step 2: Load QA Mode Map
```
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-main.mdc
```

### Step 3: Load QA Validation Checks (Sequential)
```
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-checks/dependency-check.mdc
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-checks/config-check.mdc
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-checks/environment-check.mdc
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-checks/build-test.mdc
```

### Step 4: Load QA Utilities (As Needed)
**On Success:**
```
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-utils/reports.mdc
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-utils/mode-transitions.mdc
```

**On Failure:**
```
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-utils/reports.mdc
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-qa-utils/common-fixes.mdc
```

## Workflow

1. **Verify Prerequisites**
   - Check `memory-bank/tasks.md` for planning/creative completion
   - For Level 3-4: Verify creative phase documents exist
   - Read design decisions to extract technical requirements

2. **Phase Detection**
   - Detect current development phase (VAN, PLAN, CREATIVE, BUILD)
   - Load phase-specific validation checks

3. **Universal Validation**
   - **Memory Bank Verification**: Check core files exist and are consistent
   - **Task Tracking Verification**: Validate tasks.md as source of truth
   - **Reference Validation**: Verify cross-references between documents

4. **Project Type Detection**
   - Detect project type by examining project root for characteristic files:
     - Look for dependency manifest files (files that declare project dependencies)
     - Look for build configuration files (files that define build processes)
     - Look for lock files (files that pin exact dependency versions)
     - Examine directory structure patterns (e.g., `src/`, `lib/`, `tests/`, language-specific conventions)
     - Check for language-specific configuration files in standard locations
   - Identify package manager and build system by examining:
     - Dependency manifest file format and location
     - Build tool configuration files
     - Lock file presence and format
     - Standard project structure conventions
   - Determine runtime/compiler requirements from:
     - Project configuration files
     - Dependency specifications
     - Build system requirements

5. **Technical Validation (Four-Point Check)**
   
   **1️⃣ Dependency Verification:**
   - Read required dependencies from creative phase documents
   - Check if all dependencies are installed by:
     - Examining dependency manifest files for declared dependencies
     - Checking for dependency installation artifacts (e.g., vendor directories, lock files, package caches)
     - Verifying dependencies are accessible to the build system
     - Using project's package manager commands to verify installation status
   - Verify version compatibility:
     - Compare installed versions against requirements from creative phase
     - Check for version conflicts or incompatibilities
     - Validate version constraints are satisfied
   - Identify missing or incompatible dependencies and report specific issues
   
   **2️⃣ Configuration Validation:**
   - Validate configuration file formats:
     - Identify all configuration files relevant to the project type
     - Parse and validate configuration syntax (JSON, YAML, TOML, XML, etc.)
     - Check for syntax errors or malformed configuration
   - Verify configuration integrity:
     - Ensure configuration references exist (files, packages, modules)
     - Validate configuration references installed packages/dependencies
     - Check for required configuration values based on project type and creative phase requirements
     - Verify configuration consistency across related files
   
   **3️⃣ Environment Validation:**
   - Check runtime/compiler version compatibility:
     - Identify required runtime or compiler from project configuration
     - Verify required version is available and matches requirements
     - Check version compatibility against project specifications
   - Verify build/run commands exist:
     - Examine project configuration for defined build/run scripts
     - Check for build system configuration files (Makefiles, build configs, etc.)
     - Verify build commands are properly configured
   - Validate environment setup:
     - Check required environment variables are set (if specified)
     - Verify file permissions for build artifacts and dependencies
     - Ensure build directories are accessible
   
   **4️⃣ Minimal Build Test:**
   - Run minimal build/compile test:
     - Execute project's build command in a non-destructive way (dry-run, check-only, or minimal build)
     - Verify build process completes without errors
     - Check for build artifacts or compilation output
   - Verify project structure:
     - Confirm entry point/main files exist and are correctly referenced
     - Validate file references (imports, includes, module paths, etc.) are correct
     - Check that required source files are present
   - Test basic functionality:
     - Ensure build system can process the project
     - Verify no critical configuration or dependency issues prevent building
     - Confirm project is in a buildable state

6. **Generate Validation Report**
   - Create comprehensive success or failure report
   - Write validation status to `memory-bank/.qa_validation_status`
   - Update `memory-bank/tasks.md` with validation results

7. **Handle Results**
   - **On Success**: Allow transition to BUILD mode
   - **On Failure**: Provide specific fix instructions, block BUILD mode

## Usage

Type `/niko/qa` to perform technical validation before implementation.

**Typical Workflow:**
```
/niko/plan → /niko/creative → /niko/qa → /niko/build
```

## Next Steps

- **On Success**: Proceed to `/niko/build` command for implementation
- **On Failure**: Fix identified issues and re-run `/niko/qa` until validation passes

**Note**: BUILD mode will be blocked until QA validation passes. The system checks `memory-bank/.qa_validation_status` before allowing BUILD mode access.

