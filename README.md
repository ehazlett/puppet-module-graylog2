# Puppet Module :: Graylog2

This installs and configures the (Graylog2) [http://graylog2.org] centralized logger.

## Usage

Basic

`include graylog2`

Parameters

```
class { 'graylog2':
  server_name         => 'mygraylogserver',
  external_hostname   => 'graylog.mydomain.com',
  update_local_syslog => false,
} 
```

## Customization

Edit the template files in the `templates` directory to customize email, etc.