# Contributing

**Pull requests are welcome!**

If you encounter a problem with Authenticator, feel free to [open an issue][issues]. If you know how to fix the bug or implement the desired feature, a pull request is even better.

A great pull request:
- Follows the coding style and conventions of the project.
- Adds tests to cover the added functionality or fixed bug.
- Is accompanied by a clear explanation of its purpose.
- Remains as simple as possible while achieving its intended goal.

Please note that this project is released with a [Contributor Code of Conduct][conduct]. By participating in this project you agree to abide by its terms.

[issues]: https://github.com/mattrubin/Authenticator/issues
[conduct]: CONDUCT.md


## Getting Started

1. Check out the latest version of the project:
  ```
  git clone https://github.com/mattrubin/Authenticator.git
  ```

2. Check out the project's dependencies:
  ```
  git submodule update --init --recursive
  ```

3. Open the `Authenticator.xcworkspace` file.
> If you open the `.xcodeproj` instead, the project will not be able to find its dependencies.

4. Build and run the "Authenticator" scheme.


## Managing Dependencies

Authenticator uses [Carthage] to manage its dependencies, but it does not currently use Carthage to build those dependencies. The dependency projects are checked out as submodules, are included in `Authenticator.xcworkspace`, and are built by Xcode as target dependencies of the Authenticator app.

To check out the dependencies, simply follow the "Getting Started" instructions above.

To update the dependencies, modify the [Cartfile] and run:
```
carthage update --no-build --use-submodules
```

[Carthage]: https://github.com/Carthage/Carthage
[Cartfile]: https://github.com/mattrubin/Authenticator/blob/master/Cartfile
