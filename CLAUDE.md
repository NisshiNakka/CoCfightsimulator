# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CoC (Call of Cthulhu) Battle Simulator — a Ruby on Rails 7.0 TRPG battle simulation tool. Users register characters with combat stats, then simulate automated battles using BCDice (Call of Cthulhu 7th Edition rules). Targets TRPG scenario creators who need to balance encounters.

## Commands

### Development Server
```bash
./bin/dev          # Start all processes (Rails + JS watcher + CSS watcher)
```

### Testing
```bash
bundle exec rspec                            # Run all specs
bundle exec rspec spec/models/character_spec.rb  # Run a single spec file
bundle exec rspec spec/models/               # Run all model specs
bundle exec rspec spec/system/               # Run system/E2E tests
```

System tests require Chrome driver running at `localhost:4444` (provided by Docker Compose).

### Linting & Security
```bash
bin/rubocop -A         # Auto-fix RuboCop violations
bin/brakeman --no-pager  # Security vulnerability scan
```

### Database
```bash
bin/rails db:create db:migrate db:seed  # Initial setup
bin/rails db:test:prepare               # Prepare test DB
```

### JavaScript & CSS
```bash
yarn build         # Build JS bundle (esbuild, ESM format)
yarn build:css     # Compile SCSS and add vendor prefixes
```

## Architecture

### Data Model
```
User ──has_many──> Character ──has_many──> Attack
```
- **Character**: HP (3-100), dexterity (1-200), evasion rate, armor, damage bonus
- **Attack**: name, success probability (1-100), dice correction (-10..10), damage (dice notation), range (proximity=1 / ranged=2)
- Dice notation format: `/\A\d+[dD]\d+(?:[+\-]\d+(?:[dD]\d+)?)*\z/` (e.g., `1d6`, `2d6+3`)
- Each character must have 1–3 attacks

### Battle Simulation Flow
1. `SimulationsController#combat_roll` receives form params
2. `BattleCoordinator` (`app/services/`) manages the full battle loop (max 20 turns), determines turn order from dexterity, tracks HP, declares winner
3. `BattleProcessor` (`app/services/`) handles each individual attack: rolls attack dice via BCDice, rolls evasion, applies damage and armor reduction
4. BCDice access is provided by the `DiceRollable` concern (`app/models/concerns/`) included in Character and Attack models — uses `"Cthulhu7th"` game system

### Frontend
- Hotwired (Turbo + Stimulus) for reactive updates without full page reloads
- Bootstrap 5.3 for styling; Sass compiled via `yarn build:css`
- esbuild bundles JS in ESM format

### Authentication
- Devise handles user auth; configured for email/password login
- `ApplicationController` enforces authentication globally

### Routing Key Points
```ruby
resource :simulations, only: [:new]          # Singular resource — no :id
post "combat_roll", to: "simulations#combat_roll"
resources :characters                         # Full CRUD
```

### Internationalization
- Default locale: `ja_jp` (Japanese)
- Translations live in `config/locales/`

### Testing Setup
- RSpec with FactoryBot (`spec/factories/`), documentation formatter (`.rspec`)
- System tests use Capybara with remote Chrome (`spec/support/capybara.rb`)
- Devise test helpers loaded in `spec/rails_helper.rb`

### CI (GitHub Actions)
Three parallel jobs on PRs and pushes to `main`: Brakeman scan → RuboCop lint → full test suite (`bin/rails db:test:prepare test test:system`).

### Docker
`compose.yml` runs three services: `db` (PostgreSQL), `web` (Rails), `chrome` (Selenium). Development uses `Dockerfile.dev`.
