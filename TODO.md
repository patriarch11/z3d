# TODO

## Dependencies

- [ ] **Switch `zglfw` back to upstream `main` after PR #58 is merged.**
  - PR: https://github.com/zig-gamedev/zglfw/pull/58
  - Temporary source: `daniel-szarkowicz/zglfw`, commit `12c7a6c45139e192b8ea8ea315d03dcd5553fb35` (Zig 0.17 support).
  - After the merge, update the dependency:
    ```sh
    zig fetch --save 'git+https://github.com/zig-gamedev/zglfw'
    ```
  - Check that `build.zig.zon` points to `zig-gamedev/zglfw`, not the fork.
  - Verify on macOS:
    ```sh
    zig build --build-file ./build.zig cube
    zig build --build-file ./build.zig test
    ```
  - [ ] Remove this TODO after both commands pass.
