---
task_id: svg-post-processing
date: 2026-03-12
complexity_level: 3
---

# Reflection: SVG Post-Processing

## Summary

Built SVG post-processing for the jekyll-mermaid-prebuild plugin: a new `SvgPostProcessor` module that fixes mmdc's foreignObject text-clipping bug and removes/replaces the hardcoded `max-width` inline style for responsive diagram scaling. All 7 requirements were delivered; 76 tests pass; RuboCop clean.

## Requirements vs Outcome

All 7 requirements from the project brief were implemented as specified:
- `max_width` optional config param (Configuration)
- foreignObject width correction (SvgPostProcessor)
- max-width style constraint/removal (SvgPostProcessor)
- Nokogiri runtime dependency (gemspec)
- No-op for diagrams without foreignObject pattern (guard checks in SvgPostProcessor)
- Cache key includes max_width (Processor)

One minor addition beyond the original plan: **B9a** — defensive `width="100%"` on root `<svg>`. This was identified during preflight and added as a minor improvement aligned with the responsive scaling goal. The requirement was small enough that it didn't require a creative phase.

## Plan Accuracy

The 6-step implementation sequence was accurate: dependencies first (gemspec → Configuration → SvgPostProcessor → Generator → Processor → docs). No reordering was needed. The file list was complete. The preflight correctly pre-identified the `instance_double` update requirement for generator_spec and processor_spec, which prevented a class of "unexpected message" test failures.

The documented challenges were all correctly anticipated:
- Namespace-aware XPath: required `{ "svg" => "http://www.w3.org/2000/svg" }` prefix mapping — worked cleanly
- Diverse diagram types: guard checks (`next unless rect && fo`) made the no-op path straightforward
- Transform parsing: regex on `translate(x, y)` worked as planned
- Cache migration: format change auto-invalidates as predicted

No surprises emerged from outside the anticipated risk areas.

## Creative Phase Review

No creative phase was executed — all questions were resolved in planning with high confidence, and this held up during implementation without any friction. The decision to always apply foreignObject fix (unconditionally) and optionally apply max_width translated cleanly to code.

## Build & QA Observations

**Went smoothly**: TDD cycle was clean. Each module's tests failed predictably with stubs, then passed after implementation. No unexpected API differences with Nokogiri.

**One iteration required**: The B5 test ("removes max-width inline style") initially failed after implementation. The root cause was a behavioral subtlety: when max-width is the only style declaration, the entire `style` attribute is deleted (returns `nil`) rather than set to `""`. The test's `not_to include("max-width")` cannot call `include?` on nil. Fix: `.to_s` on the style value — made the test more robust and revealed clearer intent.

**QA caught two issues**:
1. The `public`/`private` alternation anti-pattern in `generator.rb` — `post_process_svg` was stubbed in the middle of the class and never moved to the end. Trivial fix: reorder methods.
2. Unused `SVG_NS` constant in `SvgPostProcessor` — an artifact of early planning docs that referenced the namespace string directly; the final implementation only uses `NS`. Trivial fix: remove.

Neither issue was substantive — both were pure style/cleanup.

## Cross-Phase Analysis

- **Preflight → Build (positive)**: The explicit note about updating `instance_double` mocks saved time during the generator and processor TDD cycles. Without preflight's identification of this, those tests would have failed with confusing "unexpected message" errors.

- **Preflight → Build (B9a addition)**: Preflight's addition of B9a was correctly scoped. It added 1 test and ~1 line of implementation without complicating anything.

- **Plan → QA (generator method order)**: The stub-first approach placed `post_process_svg` between two public methods during scaffolding, which was never corrected during build. QA caught it. Better stubbing practice: place the stub in the architecturally correct position from the start (private methods at end of class), even when it's just a stub.

- **Plan → QA (unused constant)**: `SVG_NS` was mentioned in early planning pseudocode as a reference namespace but the final implementation absorbed it into the `NS` hash inline. A minor YAGNI slip from documentation-in-progress to code.

## Insights

### Technical

- **Nokogiri namespace-aware XPath for SVG**: When the SVG root has `xmlns="http://www.w3.org/2000/svg"`, all child elements are in the SVG namespace. XPath queries must use a namespace prefix map (`{ "svg" => "http://www.w3.org/2000/svg" }`). Without this, `//g[@class='node']` returns nothing. Using `doc.root` (instead of XPath) to find the root `<svg>` element is more reliable and namespace-agnostic.

- **Nokogiri `to_xml` adds XML declaration**: `Nokogiri::XML::Document#to_xml` prepends `<?xml version="1.0" encoding="UTF-8"?>` unless suppressed. For SVG files that were originally declaration-free (all mmdc output), this produces format drift. The clean fix is `result.sub!(/\A<\?xml[^?]*\?>\n/, "") unless svg_content.start_with?("<?xml")` — preserves the original format contract.

- **nil vs empty string for removed attributes in Nokogiri**: `element.delete("attr")` removes the attribute entirely (subsequent reads return `nil`). Conditional test helpers need `.to_s` or `&.include?` to handle this without `NoMethodError`.

### Process

- **Place stubs in their final architectural position**: When stubbing a new private method during TDD preparation, put it at the end of the class (where private methods belong), not inline near where it's called. This prevents a QA finding about method ordering.

- **Preflight's concrete impact**: The instance_double gap identification was the most concrete preflight contribution. It's worth noting that this type of "cross-file dependency impact" check (what tests need updating when a public interface gains a method?) is one of the highest-value things preflight can do for a Ruby/RSpec project.
