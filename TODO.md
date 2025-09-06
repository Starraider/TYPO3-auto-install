# TODO

## 1. .env

- Credentials einfügen

- confi.yaml
base: '%env(SITE_BASE)%'

- additional.php
```php
'dbname' => getenv('TYPO3__DB__Connections__Default__dbname'),
                    'host' => getenv('TYPO3__DB__Connections__Default__host'),
                    'password' => getenv('TYPO3__DB__Connections__Default__password'),
                    'port' => getenv('TYPO3__DB__Connections__Default__port'),
                    'user' => getenv('TYPO3__DB__Connections__Default__user'),
                    'driver' => 'mysqli',
```

## 2. language config

- confi.yaml
```yaml
languages:
  -
    title: German
    enabled: true
    languageId: 0
    base: /
    locale: de_DE.utf8
    navigationTitle: Deutsch
    flag: de
    hreflang: de-DE
    websiteTitle: ''
  -
    title: English
    enabled: true
    languageId: 1
    base: /en/
    locale: en_US.UTF-8
    navigationTitle: English
    flag: us
    hreflang: en-US
    websiteTitle: ''
```

## 3. ddev composer req skom/leseohren@dev