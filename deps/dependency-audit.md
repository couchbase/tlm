# Third-Party Dependency Verification Guide & Prompt Template

This document provides the standardized prompt and execution instructions
for team members to run automated, live upstream dependency verification
against [`deps/manifest.cmake`](manifest.cmake) and generate a
comprehensive dependency health report.

---

## Reusable AI Prompt Template

Copy and paste the prompt below into your assistant session to perform
the verification:

````markdown
Please perform a live upstream dependency assessment for all
third-party dependencies declared in `deps/manifest.cmake`.

### Instructions & Rules:
1. **Live Upstream Verification**:
   - Do NOT rely on model pre-trained assumptions or memory.
   - Query the live canonical upstream open-source repositories (e.g.,
     via GitHub Releases/Tags API) where Couchbase originally
     sourced/forked each dependency (do NOT check `couchbasedeps`
     forks).
2. **Release Constraints**:
   - Ignore release candidates, beta releases, and previews (e.g.,
     `-rc`, `-beta`, `-alpha`). Only consider official stable releases.
   - Where applicable (e.g., OpenSSL, Java, Node/V8, Linux tools),
     prioritize Long Term Support (LTS) or active production lines.
3. **Version Normalization**:
   - Strip Couchbase-specific decorations (`-cbN` suffixes, `V2`/`BUILD
     n` markers) from the manifest version before comparing it to the
     upstream version — compare against the underlying upstream base
     version only.
4. **Quantitative Claims**:
   - Only state specific performance numbers (e.g., throughput %,
     memory reduction) or CVE identifiers if they are explicitly
     documented in that project's own release notes/changelog. Cite or
     reference the source.
   - Do not invent or estimate percentages/benchmarks that aren't
     documented upstream — describe undocumented improvements
     qualitatively instead.
   - When citing a CVE, verify the CVE's affected-version range
     actually covers the pinned manifest version before listing it as
     a resolved/applicable fix.
5. **Snapshot / Rolling-Release Dependencies**:
   - For dependencies without semantic version tags (e.g., `folly`,
     `fuzztest`, `breakpad`), compare by latest commit date or
     snapshot tag date rather than semantic version number.
6. **Generate a Full Report (`dependency-status.md`)** structured with
   the following sections:
   - **Section 1: Executive Summary & Categorization**:
     - *1.1 Significantly Older / Legacy Dependencies*: Table listing
       packages with major lag/age gap, current manifest version,
       live upstream latest, and risk/age gap.
     - *1.2 Up-to-Date or Actively Maintained Dependencies*: Table
       listing packages tracking recent stable branches.
   - **Section 2: Detailed Dependency Breakdown & Upgrade Analysis**:
     - For every dependency in alphabetical order, document:
       - Current Version vs. Live Upstream Latest.
       - Summary of new features & capabilities.
       - Measurable performance improvements (SIMD, throughput,
         memory reductions).
       - Known security fixes & CVE identifiers resolved upstream.
   - **Section 3: Recommended Phased Upgrade Roadmap**:
     - A prioritized execution plan (Phases 1 to 5) based on risk
       profile, blast radius, engineering effort, and ROI.
     - Include a Mermaid diagram illustrating the phase progression.
     - Note compiler/toolchain baseline requirements (e.g. C++23).
   - **Section 4: Upgrade Workflow & Release Checklist**:
     - Standardized operational steps covering `couchbasedeps` recipe
       creation, `deps/manifest.cmake` updates,
       `couchbase-server-black-duck-manifest.yaml` synchronization,
       and multi-platform CI verification.
````
