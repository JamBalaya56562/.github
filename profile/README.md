# aletheia-works

**Universal bug reproduction in the AI era.**

We build tools that let anyone reproduce a bug — any language, any environment, any scale — so the community can verify what is actually true when AI-generated claims flood issue trackers.

## Active projects

- **[vivarium](https://github.com/aletheia-works/vivarium)** — a controlled environment for reproducing bugs, any language, any environment, any scale. Reproductions run across three layers, each chosen by what the bug demands: WASM verticals (Pyodide, Ruby.wasm, php-wasm, Rust on `wasm32-wasip1`) for instant, browser-native runs; Docker recipes published to `ghcr.io/aletheia-works/` for full-fidelity environments; and record-replay with `rr` for bugs that only surface under deterministic execution. Every reproduction emits a machine-readable verdict, and the public specs — Contract v1, Manifest v1, and the Recipes index — let outside repositories declare their own runnable reproductions. A Vivarium MCP server exposes the catalogue and verdicts to AI agent clients.

## Why "aletheia"?

*Aletheia* (ἀλήθεια) is the ancient Greek word for "unconcealment" — truth understood as what emerges when hidden things are brought into the open. In an era where AI-generated claims flood issue trackers, the work of separating real bugs from plausible-but-false ones is increasingly the work of a truth-disclosure tool.

## Philosophy

- **Problem-centered, not technology-centered.** We reach for WASM, Docker, microVMs, or record-replay based on what the bug demands — never the other way around.
- **Lifelong project.** We plan in decades, not quarters.
- **AI-delegated development.** Human strategy, AI implementation, both held accountable.

## License

All code ships under Apache License 2.0 unless a repository explicitly states otherwise.
