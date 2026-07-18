# LM Studio Status Widget

Native macOS widget-style app for checking a local LM Studio server.

It shows:

- whether the LM Studio server responds
- currently loaded models
- active token generation (`GEN`), observed duration, and queued requests
- the endpoint used for the latest successful check

Requirements:

- macOS 15 or newer
- Xcode Command Line Tools
- LM Studio local server on port `1234`

Default server URL:

```text
http://localhost:1234
```

Run locally:

```bash
./script/build_and_run.sh
```

The app polls `/api/v1/models` first and falls back to the OpenAI-compatible `/v1/models` endpoint.
For a local server it also reads the supported `lms ps --json` runtime status. LM Studio does not expose
another client's exact live token count through this interface, so the widget shows the exact generation
state and how long it has observed it instead of estimating a misleading token number.

## Privacy

The app communicates only with the LM Studio server URL configured by the user.
It contains no analytics, telemetry, advertising, or bundled credentials.

## License and credits

This project is open source under the [MIT License](LICENSE).

Copyright (c) 2026 R3D42
