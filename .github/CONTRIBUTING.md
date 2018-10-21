## How to contribute to SLRNetworkMonitor

Thanks for contributing! The following is a set of guidelines for contributions to this project. As Pirates of the Caribbean pointed out, guidelines != rules. Therefore, use your best judgement and feel free to propose changes to this process.

This project adheres to the [Contributor Covenant v1.4.1](CODE_OF_CONDUCT.md), so you are expected to uphold the requirements of that Code of Conduct.

Also, contributions are only accepted if the committer accepts the Contributor License Agreement (CLA). This project uses the Developer Certificate of Origin (DCO):
> Developer Certificate of Origin
> Version 1.1
>
> Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
>
> 1 Letterman Drive
>
> Suite D4700
>
> San Francisco, CA, 94129
>
> Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.
>
>
> Developer's Certificate of Origin 1.1
>
> By making a contribution to this project, I certify that:
>
> (a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or
>
> (b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or
>
> (c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.
>
> (d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

### Submitting Issues

1. Search the [open issues](https://github.com/madsolar8582/SLRNetworkMonitor/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen) for any issue that resembles your own.
2. Search the [closed issues](https://github.com/madsolar8582/SLRNetworkMonitor/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aclosed) for any issue that resembles your own.
3. If you can't find anything resembling the feature request that you want or bug report for a bug that you are experiencing, open a new issue using the respective issue template (`Bug Report` or `Feature Request`) with a descriptive title. Support requests (usage/installation questions) should use their respective process (see [SUPPORT](SUPPORT.md) for details).

Barring vacations/holidays, the issue will be looked at within 3 business days.

### Submitting Pull Requests

Please open a corresponding issue first. This allows for agreement on the implementation for a bug fix or feature request before you start working on it (possibly saving you lots of time). However, if the change is to fix a typo or add documentation, a direct pull request is ok.

* All pull requests should be based off of the `master` branch. Please do not include any unmerged changes from other branches.
* All pull requests should be scoped to one change only. Seemingly trivial changes alongside other changes may have unforeseen consequences. By limiting the number of changes in a pull request, it makes bug isolation much easier.
* All pull requests must have a descriptive title (avoid Fixes #XXXX).
* All pull requests must adhere to the project's code standards (see below).
* All pull requests are checked by a few automated systems. Please ensure that your change passes these checks.
* Changes must have corresponding test updates (if applicable).
* Changes must have corresponding documentation updates (if applicable).
* Changes must not introduce static analysis issues ([ASan](https://developer.apple.com/documentation/code_diagnostics/address_sanitizer?language=objc), [TSan](https://developer.apple.com/documentation/code_diagnostics/thread_sanitizer?language=objc), [UBSan](https://developer.apple.com/documentation/code_diagnostics/undefined_behavior_sanitizer?language=objc), [MTC](https://developer.apple.com/documentation/code_diagnostics/main_thread_checker?language=objc), & [Static Analyzer](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/debugging_with_xcode/chapters/static_analyzer.html)).

Barring vacations/holidays, the issue will be looked at within 3 business days.

### Code Standards

#### Principles

1. Optimize for the reader.
2. Be consistent.
3. Follow [Apple guidelines](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).

#### Standards

1. All code must be modern Objective-C (dot syntax, property methods, object literals, etc).
2. All code must be written in a Swift friendly way.
3. Code must be annotated for SDK availability if there are SDK version requirements.
4. Exported constants/global types must be properly exported via `FOUNDATION_EXPORT`.
5. Enums must be properly `typdef`'d with `NS_ENUM` or `NS_ERROR_ENUM`.
6. Variables and methods should have meaningful and descriptive names.
7. Properties should include their atomicity, ARC qualifier, & nullability.
8. System headers must be imported as both a module and regular import to support both types of consumers.
9. Documented parameters should be aligned to the longest parameter.
10. Implementation files should be split up logically via `#pragma`s.
