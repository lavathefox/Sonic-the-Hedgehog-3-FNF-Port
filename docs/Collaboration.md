# Collaboration & Contribution Guide

Thank you for your interest in contributing to **Sonic the Hedgehog 3 FNF Port**. This document describes how to collaborate responsibly, propose changes, contribute assets, report issues, and help maintain a stable experience across supported platforms.

> **Project repository:** https://github.com/lavathefox/Sonic-the-Hedgehog-3-FNF-Port
>
> **Scope:** A community fan project built with Haxe/HaxeFlixel and related Friday Night Funkin' modding technologies. Contributions are reviewed at the maintainers' discretion; submitting a contribution does not guarantee its inclusion.

## 1. Collaboration Principles

We value contributions that are:

- **Respectful:** Discuss ideas and technical disagreements without personal attacks.
- **Transparent:** Describe what changed, why, and how it was tested.
- **Maintainable:** Favor readable, focused changes over unnecessary complexity.
- **Compatible:** Consider both desktop and Android behavior, including performance and input differences.
- **Responsible:** Respect intellectual property, contributor consent, user privacy, and software licenses.

## 2. Ways to Contribute

| Area | Examples | Recommended evidence |
| --- | --- | --- |
| Engine and gameplay | Haxe code, note handling, timing, menus, input | Reproduction steps, test results |
| Android and desktop | Build fixes, storage, touch controls, performance | OS/build details, logs |
| Visuals | Original sprites, animation, UI, shaders | Screenshots, previews, source attribution |
| Audio | Original music, sound effects, mixing, synchronization | Preview, timing notes, rights statement |
| Testing | Bug reports, regression testing, accessibility checks | Steps, expected/actual behavior |
| Documentation | Setup guides, translations, technical references | Clear examples and review notes |

For large features, major redesigns, new dependencies, or substantial asset packs, **open an issue before starting** to align on scope and avoid duplicated work.

## 3. Getting Started

1. Review the repository's README, existing issues, open pull requests, and applicable licenses.
2. Fork the repository, or work in an authorized branch if you have collaborator access.
3. Create a focused branch, for example `feat/android-touch-controls`, `fix/audio-sync`, or `docs/build-guide`.
4. Make your changes while preserving existing public APIs unless the change is discussed and justified.
5. Test your work on relevant targets, or clearly explain which targets you could not test.
6. Open a pull request against the appropriate default or development branch.

### Suggested Git workflow

```bash
git clone https://github.com/YOUR_USERNAME/Sonic-the-Hedgehog-3-FNF-Port.git
cd Sonic-the-Hedgehog-3-FNF-Port
git checkout -b fix/describe-the-problem
# Make and test your changes
git add .
git commit -m "fix: describe the correction"
git push -u origin fix/describe-the-problem
```

Replace `YOUR_USERNAME` with your GitHub username. Build commands and dependencies may vary by branch; use the repository's current setup instructions as the source of truth.

## 4. Engineering Standards

### Haxe and HaxeFlixel

- Follow the existing package layout, naming conventions, and formatting in neighboring files.
- Prefer small, cohesive classes and functions with clear responsibilities.
- Guard platform-specific APIs using appropriate compile-time conditions (`#if android`, `#if desktop`, etc.).
- Avoid unnecessary allocations inside frame updates, note-processing loops, and rendering paths.
- Handle missing assets, null values, malformed data, and failed external operations gracefully.
- Do not introduce noisy logging, debug overlays, or test-only behavior into release builds.
- Avoid modifying unrelated code or mass-formatting entire files in a focused bug fix.
- Explain API changes that affect mods, scripts, save files, or other engine systems.

### Lua, HScript, and mod compatibility

- Keep scripts compatible with the interpreter and engine version used by the project.
- Do not assume a script API exists on every platform or engine fork.
- Validate resource paths and avoid persistent global state when local state is sufficient.
- Document changes that affect existing mod scripts, events, or configuration formats.

### Android-specific changes

- Consider touch input, lifecycle transitions, screen sizes, memory pressure, and lower-powered devices.
- Request only permissions needed for a documented feature.
- Avoid hardcoded storage paths and unsafe assumptions about modern Android storage access.
- Test native/JNI changes separately from ordinary Haxe changes when possible.
- Never include signing keys, keystores, tokens, credentials, or private device data in commits or logs.

### Dependencies and build configuration

- Explain why a new dependency is necessary and which targets it supports.
- Avoid upgrading libraries or SDK requirements as part of unrelated changes.
- Include relevant build output when changing `Project.xml`, manifests, Gradle configuration, or CI workflows.
- Do not claim a build passed unless it was actually run successfully.

## 5. Quality Assurance

Before submitting, verify the relevant items:

- The project builds or the pull request clearly states why it could not be built.
- Gameplay timing, input, and audio remain correct for affected scenes.
- Assets load without missing-file errors and are correctly referenced on case-sensitive systems.
- UI changes work at different resolutions and with touch controls where applicable.
- Save data and settings are not unintentionally reset or corrupted.
- Performance-sensitive changes have been checked for avoidable regressions.
- Any newly discovered limitations are documented.

**Testing matrix** (mark only what you actually tested):

| Target | Build | Launch | Gameplay | Notes |
| --- | --- | --- | --- | --- |
| Windows | ☐ | ☐ | ☐ | |
| Android | ☐ | ☐ | ☐ | |
| Other | ☐ | ☐ | ☐ | Specify target |

## 6. Reporting Issues

Use [GitHub Issues](https://github.com/lavathefox/Sonic-the-Hedgehog-3-FNF-Port/issues) to report bugs, suggest improvements, or request clarification.

A useful bug report includes:

```markdown
## Summary
Describe the problem in one or two sentences.

## Steps to Reproduce
1. ...
2. ...
3. ...

## Expected Behavior
What should happen?

## Actual Behavior
What happens instead?

## Environment
- Commit/build:
- Platform and OS version:
- Device or hardware (if relevant):
- Mods/settings involved:

## Evidence
Attach sanitized logs, screenshots, or a short recording.

## Additional Context
Possible regression, workaround, or related issue.
```

Search existing issues before filing a new one. Never publish private tokens, personal identifiers, or sensitive information in logs or screenshots.

## 7. Pull Request Requirements

Keep pull requests reasonably scoped. Include a description of the motivation, implementation, risks, and verification steps. Link related issues where available.

### Pull request template

```markdown
## Summary
What does this PR change?

## Motivation
Why is this change needed?

## Implementation
What are the key technical decisions?

## Related Issues
Closes #... (if applicable)

## Testing
- [ ] Windows build tested
- [ ] Android build tested
- [ ] Relevant gameplay/manual tests completed
- [ ] Existing functionality checked for regressions

## Media / Logs
Screenshots, video, or sanitized logs, if relevant.

## Compatibility and Risks
Describe API changes, save-data impacts, performance concerns,
or platforms not tested.

## Contributor Checklist
- [ ] I reviewed existing issues and pull requests.
- [ ] My changes are focused and understandable.
- [ ] I have the rights to submit all included code and assets.
- [ ] I preserved required license notices and credits.
- [ ] I did not commit credentials or private information.
- [ ] I documented any known limitations.
```

Maintainers may request changes, defer a proposal, or close a pull request that is out of scope, incomplete, unsafe, or legally problematic. Review comments should focus on the contribution, not the contributor.

## 8. Commit and Branch Conventions

Recommended commit prefixes:

- `feat:` new feature
- `fix:` bug fix
- `refactor:` internal code restructuring
- `perf:` performance improvement
- `docs:` documentation
- `test:` tests and verification
- `build:` dependencies or build system
- `ci:` automation workflows
- `chore:` maintenance

Examples: `fix: restore Android pause input`, `perf: reduce shader allocations`, `docs: clarify mod folder structure`.

These conventions are recommendations, not a substitute for repository-specific maintainer instructions.

## 9. Art, Music, Attribution, and Licensing

This is a **fan project**. References to Sonic, Friday Night Funkin', or other third-party properties do not imply endorsement by their respective rights holders.

- Submit only work you created, work you have permission to redistribute, or work whose license permits the proposed use.
- Identify third-party material, its original creator, source, license, and any required attribution.
- Do not submit ripped commercial assets, copyrighted music, proprietary code, or other material without appropriate rights or authorization.
- Do not remove existing credits, copyright notices, or license files.
- For collaborations involving multiple creators, confirm that each contributor agrees to the submission and credit arrangement.
- Disclose AI-assisted content when its origin or rights may affect project review, and verify that it can be lawfully used.

**Important:** This guide does not itself grant a license to reuse repository content. Check the actual license and rights status of each component before redistribution. If the repository has no applicable license, obtain permission before reusing its contents outside the permitted contribution workflow.

## 10. Security and Privacy

- Do not commit secrets, access tokens, signing credentials, or private configuration.
- Do not add telemetry, analytics, network calls, or permissions without explaining their purpose.
- Avoid exposing player files, device identifiers, or personally identifiable information.
- If you discover a potentially exploitable security issue, contact the maintainers privately when a suitable private contact method is available; avoid posting exploitation details publicly before coordination.

## 11. Communication and Conduct

All contributors are expected to:

- Treat others respectfully regardless of experience, identity, or background.
- Provide constructive feedback and accept technical review in good faith.
- Avoid harassment, hate speech, threats, doxxing, spam, and deliberate disruption.
- Respect boundaries, consent, and contributor credit agreements.
- Keep project discussions focused and collaborative.

Maintainers may moderate discussions and restrict participation when necessary to protect the community.

## 12. Maintenance and Decision-Making

Maintainers are responsible for deciding what enters the project, balancing compatibility, scope, performance, quality, and legal concerns. They may request additional tests, changes, or documentation before merging. Features that are valuable but outside the current roadmap may be postponed.

If a proposal is declined, contributors are welcome to request a technical explanation or propose an alternative approach respectfully.

## 13. Recognition

Contributors should be credited in a manner appropriate to their work and the project's existing credits system. When submitting third-party assets or work made jointly with others, provide the preferred credit names and any attribution obligations.

Thank you for helping improve **Sonic the Hedgehog 3 FNF Port**! 💚🦔
