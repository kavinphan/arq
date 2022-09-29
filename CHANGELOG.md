## [Unreleased]

- Refactor ModuleHash to ActionModuleHash.
- De-dupe action/module handling from Action into ActionModuleHash.

## [0.3.0] - 2022-09-28

- Remove support for running lists of actions and anonymous actions.
- Add Active Support gem
- Refactor Runnable into Action
- Remove Runnable
- Support calling other actions via snake-cased paths with dot-accessors.

## [0.2.1] - 2022-09-08

- Default `Action#call` param to new context
- Default failure message parameter to nil
- Fix context and instance variable syncing before and after actions

## [0.2.0] - 2022-09-06

- Refactor FailureError to extend Exception
  - Changed to avoid failures being rescued
- (Internal) refactored all library requires to be relative

## [0.1.3] - 2022-09-05

- Correct changelog URI in metadata

## [0.1.2] - 2022-09-05

- Update Gemfile lock

## [0.1.1] - 2022-09-05

- Add documentation URI

## [0.1.0] - 2022-09-04

- Initial release
