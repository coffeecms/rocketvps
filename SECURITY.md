# Security Policy

## Supported Versions

Currently, RocketVPS is in its initial release. Security updates will be provided for the following version:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Features

RocketVPS includes three tiers of security:

### Basic Security
- SSH key authentication
- Basic firewall configuration
- Automatic security updates

### Medium Security (Recommended)
- All Basic features
- Fail2Ban protection
- Root login disabled
- Enhanced SSH hardening
- Database security

### Advanced Security
- All Medium features
- ModSecurity WAF
- Intrusion detection system
- Advanced firewall rules
- Regular security audits

## Reporting a Vulnerability

If you discover a security vulnerability in RocketVPS, please follow these steps:

### 1. Do Not Disclose Publicly

Please do not open a public GitHub issue for security vulnerabilities.

### 2. Report Privately

Email security concerns to: **your.email@example.com**

Include in your report:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### 3. Response Timeline

- **Within 24 hours**: We'll acknowledge receipt of your report
- **Within 7 days**: We'll provide an initial assessment
- **Within 30 days**: We'll release a fix or provide a remediation plan

### 4. Disclosure

Once the vulnerability is fixed:
- We'll release a security update
- We'll credit you in the release notes (if you wish)
- We'll publish a security advisory

## Security Best Practices

When using RocketVPS:

1. **Always apply at least Medium security level**
2. **Keep your system updated**: Run `rocketvps` → Menu 13 → Option 7
3. **Regular backups**: Configure automatic backups
4. **Monitor logs**: Check logs regularly via Menu 13 → Option 2
5. **Use strong passwords**: For database, FTP, Redis
6. **Enable SSL**: For all domains handling sensitive data
7. **Configure firewall**: Block unnecessary ports
8. **Regular security audits**: Run Menu 12 → Option 9

## Known Security Considerations

### Root Access Required

RocketVPS requires root access to:
- Install and configure system packages
- Modify system configuration files
- Manage services

**Mitigation**: Review the source code before installation. All code is open-source.

### Password Storage

- Database passwords are stored in `/opt/rocketvps/config/database.conf`
- Redis passwords in Redis configuration
- Cloud backup credentials in `/opt/rocketvps/config/cloud_backup.conf`

**Mitigation**: These files have restricted permissions (600).

### SSL Certificates

Let's Encrypt certificates are stored in `/etc/letsencrypt/`

**Mitigation**: Automatic renewal ensures certificates don't expire.

## Security Updates

Security updates will be announced via:
- GitHub Security Advisories
- Release notes
- Email (for reported vulnerabilities)

## Third-Party Dependencies

RocketVPS uses several third-party tools:
- Nginx
- PHP
- MariaDB/MySQL/PostgreSQL
- Redis
- CSF Firewall
- Fail2Ban
- ModSecurity
- ClamAV

**Important**: Keep these dependencies updated using RocketVPS update features.

## Compliance

RocketVPS is designed with security best practices in mind but may require additional configuration for specific compliance requirements (GDPR, HIPAA, PCI-DSS, etc.).

Consult with security professionals for compliance-critical deployments.

## Security Checklist

- [ ] Applied Medium or Advanced security
- [ ] Disabled root SSH login
- [ ] Configured firewall
- [ ] Enabled SSL for all domains
- [ ] Setup automated backups
- [ ] Changed default passwords
- [ ] Configured Fail2Ban
- [ ] Regular security audits scheduled
- [ ] System updates automated
- [ ] Monitoring logs regularly

## Questions?

For security questions that are not vulnerabilities, open a GitHub Discussion or email us.

---

**Last Updated**: 2025-10-03
