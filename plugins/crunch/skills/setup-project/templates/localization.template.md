## Localization

**Framework**: {i18n_framework}
**Management**: {translation_management}
**Source**: `{locales_path}`

### Supported Languages

| Language | Code | Status | Completeness |
|----------|------|--------|--------------|
| English | `en` | Default | 100% |
| {lang_2} | `{code_2}` | {status_2} | {percent_2}% |
| {lang_3} | `{code_3}` | {status_3} | {percent_3}% |

### File Structure

```
{locales_directory_structure}
```

### Commands

| Command | Description |
|---------|-------------|
| `{extract_cmd}` | Extract strings from code |
| `{push_cmd}` | Push to translation management |
| `{pull_cmd}` | Pull translations |
| `{validate_cmd}` | Validate translation files |

### Adding Translations

1. Add key to `{default_locale_file}`
2. Push to management: `{push_cmd}`
3. Translators complete translations
4. Pull updates: `{pull_cmd}`
5. Validate: `{validate_cmd}`

### Usage

```{language}
{usage_example}
```

### Key Naming Convention

| Pattern | Example | Use For |
|---------|---------|---------|
| `{pattern_1}` | `{example_1}` | {use_1} |
| `{pattern_2}` | `{example_2}` | {use_2} |

### Pluralization

```{language}
{pluralization_example}
```

### Date/Number Formatting

- Dates: {date_format_lib}
- Numbers: {number_format_lib}
- Currencies: {currency_format_lib}

### Testing

```bash
# Test with specific locale
{test_locale_cmd}

# Check for missing translations
{check_missing_cmd}
```
