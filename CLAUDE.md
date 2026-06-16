# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Agrammon is a simulation model for calculating ammonia and NOx emissions from agriculture. This is a port of the original application to Raku (formerly Perl 6), combining a Raku backend with a Qooxdoo JavaScript frontend.

The system processes agricultural input data through hierarchical model modules (written in a custom `.nhd` format) containing formulas that calculate emission outputs. Models are compiled at runtime into executable Raku code.

## Technology Stack

- **Backend**: Raku 6.*
- **Frontend**: Qooxdoo (JavaScript framework)
- **Database**: PostgreSQL
- **Web Framework**: Cro (HTTP server, routing, sessions)
- **Excel generation**: Native Raku XLSX writer (`Agrammon::OutputFormatter::XLSXWriter` / `ExcelNative`)

## Development Commands

### Installation & Setup

```bash
# Bootstrap and configure (first time)
mkdir -p public
./bootstrap
./configure
./make

# Install Raku dependencies
zef --debug --/test --deps-only --test-depends install .
```

### Running Tests

```bash
# Run all tests
prove6 -l t/

# Run specific test file
raku -Ilib t/model.rakutest

# Run only unit tests (skip integration tests requiring database)
AGRAMMON_UNIT_TEST=1 prove6 -l t/

# Run single test with database (requires PostgreSQL setup)
AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib t/dataset.rakutest
```

**Important**: Integration tests require PostgreSQL. Tests check `%*ENV<AGRAMMON_UNIT_TEST>` - if set, database-dependent tests are skipped.

### Running the Application

```bash
# Web application — dev server against the local podman dev DB
# (start it with `make dev-db-start`); SOURCE_MODE serves the qooxdoo source target
./runWebDev.sh

# Command line interface
raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.single.yaml web version6.5.2/End.nhd
```

Different model variants:
- `./runSingle6.5.2.sh` / `./runSingle7.sh` - Single farm model (v6.5.2 / v7.0.0; dev ports 20001 / 20002)
- `./runRegional.sh` - Regional model
- `./runKantonal.sh` - Cantonal model

### Frontend Development

```bash
cd frontend

# Install frontend dependencies
npm install

# Development mode (watch for changes)
npx qx compile --watch --feedback=false

# Production build
npx qx compile --target=build --feedback=false --erase --update-po-files
```

## Architecture

### Model System

The core innovation is the `.nhd` (Agrammon module) file format for defining calculation models:

- **Location**: `share/Models/version6/`
- **Entry Point**: `share/Models/version6/End.nhd`
- **Structure**: Models form a hierarchical tree through module references
- **Sections**: Each `.nhd` file contains metadata, inputs, outputs, technical parameters, and formulas

**Flow**:
1. `Agrammon::ModuleParser` parses `.nhd` files into AST
2. `Agrammon::Formula::Parser` parses formulas within modules
3. `Agrammon::Formula::Compiler` compiles formulas to executable Raku code
4. `Agrammon::Model` loads and validates the module tree
5. Runtime: Input data flows through modules, formulas calculate outputs

### Key Components

**Model Loading** (`lib/Agrammon/Model.rakumod`):
- Loads hierarchical model modules from `.nhd` files
- Validates inputs, outputs, and formula dependencies
- Manages module instances and multi-instance modules

**Formula System** (`lib/Agrammon/Formula/`):
- Custom DSL for agricultural calculations
- Compiles to Raku code at model load time
- Supports conditionals, loops, and references to other module outputs

**Data Sources** (`lib/Agrammon/DataSource/`):
- CSV, JSON, and PostgreSQL database input support
- `Agrammon::Inputs` represents input data for model runs
- `Agrammon::Outputs` collects calculation results

**Web Service** (`lib/Agrammon/Web/`):
- `Service.rakumod` - Core business logic
- `APIRoutes.rakumod` - REST API endpoints (see `share/agrammon.openapi`)
- `Routes.rakumod` - Web UI routes
- Uses Cro for HTTP handling and PostgreSQL sessions

**Output Formatters** (`lib/Agrammon/OutputFormatter/`):
- Multiple output formats: CSV, JSON, Text, PDF, Excel
- Excel generation uses a native Raku XLSX writer (`XLSXWriter` / `ExcelNative`) — no external dependencies

### Database Schema

PostgreSQL tables for users, datasets, tags, variants, and session management. Connection managed via `Agrammon::DB` and Cro's session store.

Database connection uses a dynamic variable: `$*AGRAMMON-DB-CONNECTION`

## Testing Conventions

- Test files use `.rakutest` extension
- Unit tests use Raku's `Test` module (`plan`, `is`, `ok`, `lives-ok`, `subtest`, etc.)
- Test data located in `t/test-data/`
- Database tests require `AGRAMMON_CFG` environment variable pointing to config with test database
- Use `if %*ENV<AGRAMMON_UNIT_TEST> { skip-rest 'Not a unit test'; exit; }` pattern for integration tests

## Configuration

Configuration files use YAML format (see `t/test-data/agrammon.cfg.yaml`):
- `General`: Logging, temp directories, PDF generation
- `Database`: PostgreSQL connection parameters
- `GUI`: Frontend settings, translations
- `Model`: Model path, variant, version

## Common Patterns

**Running Models**:
```raku
my $model = Agrammon::Model.new(:$path);
$model.load('End.nhd');
my $input = Agrammon::Inputs.new;
$input.add-single-input('Module::Name', 'input_variable', $value);
my %outputs = $model.run(:$input).get-outputs-hash();
```

**Database Transactions**:
```raku
$*AGRAMMON-DB-CONNECTION.execute(q:to/STATEMENT/);
    -- SQL here
STATEMENT
```

**Output Formatting**:
```raku
my $formatter = Agrammon::OutputFormatter::CSV.new;
my $output = $formatter.format($outputs, :$model);
```

## Code Style

- Raku uses `.rakumod` for modules, `.raku` for scripts, `.rakutest` for tests
- Sigils: `$` (scalar), `@` (array), `%` (hash), `&` (callable)
- Method calls use `.` (e.g., `$obj.method()`)
- Named parameters use `:` (e.g., `:$variable` or `:name($value)`)
- Class attributes declared with `has` (e.g., `has $.attribute`)

## Important Notes

- The project uses GNU Autotools (`./bootstrap`, `./configure`, `./make`) for build orchestration
- Frontend compilation outputs to `public/` directory
- Model files should never be edited directly in production; use version control
- Database schema changes require manual migration (no ORM)
- REST API documentation: https://redocly.github.io/redoc/?url=https://model.agrammon.ch/single/api/v1/openapi.yaml
