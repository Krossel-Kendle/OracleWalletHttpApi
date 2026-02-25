# OracleWalletHttpApi

Oracle Wallet desktop manager (Delphi VCL, Win32) with a local HTTP API.

## What this app does

- Lists certificates from an Oracle Wallet.
- Adds/removes certificates.
- Bulk-imports certificates from a folder.
- Removes all certificates from a wallet.
- Creates a brand-new wallet from UI (`Add New Wallet` menu).
- Exposes local API (`/api/v1/...`) with auth.
- Supports Enhanced API for ACL operations through `sqlplus`.
- Supports UI localization: RU / EN / ID.

## Requirements

- Windows.
- Oracle tools:
  - `orapki` (required for wallet operations);
  - `sqlplus` (required for Enhanced API ACL endpoints).
- For building from source: Embarcadero Delphi (VCL, Win32).

## Build and Run

1. Open `OraWalletHttpApi.dproj` in Delphi.
2. Build for `Win32`.
3. Run `OraWalletHttpApi.exe`.

The app stores runtime config in `config/settings.json` near the executable.

## UI Quick Start

### Connect an existing wallet

- Menu: `Wallet Configuration -> Configure`.
- Set wallet folder path and password.

### Create a new wallet

- Root menu item: `Add New Wallet`.
- This menu item is automatically disabled if `orapki` is not available.
- Fill wallet path + password + auto-login options.
- On success, app switches active wallet to the newly created one.

### Logs tab

- `Log` tab shows the latest 100 UI log lines.

## API Configuration

Open `App -> Settings`:

- Enable/disable API server.
- API port (default: `8089`).
- Auth mode:
  - `X-API-Key` header;
  - `Basic` auth.
- Allowed hosts:
  - all;
  - IP allow-list.
- Enhanced API settings:
  - PDB;
  - ACL admin user/password;
  - `tnsnames.ora` path.

## API Contract

- Base URL: `http://127.0.0.1:<port>/api/v1`.
- Runtime success/error payloads follow **JSON:API** (`application/vnd.api+json`), except:
  - `GET /api/v1/openapi.json` returns `application/json`.
- POST endpoints accept:
  - JSON:API body (`data.type`, `data.attributes`);
  - flat legacy JSON (for backward compatibility).

## Swagger / OpenAPI

- YAML spec file: `openapi.yaml` (this repository).
- Runtime JSON OpenAPI endpoint: `GET /api/v1/openapi.json`.

Import `openapi.yaml` into Swagger UI / Redoc to browse endpoints.

## Security Notes

- Sensitive values are persisted as encrypted `*Enc` settings fields.
- Command-line passwords are masked in logs.
- Do not commit runtime files like `config/settings.json` or `logs/*.log`.

## Example: Create Wallet (JSON:API)

```json
{
  "data": {
    "type": "wallets",
    "attributes": {
      "path": "C:\\app\\wallet_new",
      "password": "StrongPass123",
      "autoLogin": true,
      "autoLoginLocal": false,
      "switchToNew": true
    }
  }
}
```

## License

See `LICENSE`.
