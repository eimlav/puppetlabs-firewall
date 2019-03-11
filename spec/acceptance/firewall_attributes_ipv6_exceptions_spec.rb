require 'spec_helper_acceptance'

describe 'firewall attribute testing, exceptions', unless: (os[:family] == 'redhat' && os[:release].start_with?('5', '6')) || (os[:family] == 'sles') do
  before(:all) do
    iptables_flush_all_tables
    ip6tables_flush_all_tables
  end

  describe 'attributes test' do
    describe 'hop_limit' do
      context 'when invalid' do
        pp43 = <<-PUPPETCODE
            class { '::firewall': }
            firewall { '571 - test':
              ensure => present,
              proto => tcp,
              port   => '571',
              action => accept,
              hop_limit => 'invalid',
              provider => 'ip6tables',
            }
        PUPPETCODE
        it 'applies' do
          apply_manifest(pp43, expect_failures: true) do |r|
            expect(r.stderr).to match(%r{Invalid value "invalid".})
          end
        end

        it 'does not contain the rule' do
          shell('ip6tables-save') do |r|
            expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m multiport --ports 571 -m comment --comment "571 - test" -m hl --hl-eq invalid -j ACCEPT})
          end
        end
      end
    end

    describe 'src_range' do
      context 'when 2001::db8::1-2001:db8::ff' do
        pp52 = <<-PUPPETCODE
          class { '::firewall': }
          firewall { '601 - test':
            proto     => tcp,
            port      => '601',
            action    => accept,
            provider  => 'ip6tables',
            src_range => '2001::db8::1-2001:db8::ff',
          }
        PUPPETCODE
        it 'applies' do
          apply_manifest(pp52, expect_failures: true) do |r|
            expect(r.stderr).to match(%r{Invalid IP address "2001::db8::1" in range "2001::db8::1-2001:db8::ff"})
          end
        end

        it 'does not contain the rule' do
          shell('ip6tables-save') do |r|
            expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m iprange --src-range 2001::db8::1-2001:db8::ff -m multiport --ports 601 -m comment --comment "601 - test" -j ACCEPT})
          end
        end
      end
    end

    describe 'dst_range' do
      context 'when 2001::db8::1-2001:db8::ff' do
        pp54 = <<-PUPPETCODE
          class { '::firewall': }
          firewall { '602 - test':
            proto     => tcp,
            port      => '602',
            action    => accept,
            provider  => 'ip6tables',
            dst_range => '2001::db8::1-2001:db8::ff',
          }
        PUPPETCODE
        it 'applies' do
          apply_manifest(pp54, expect_failures: true) do |r|
            expect(r.stderr).to match(%r{Invalid IP address "2001::db8::1" in range "2001::db8::1-2001:db8::ff"})
          end
        end

        it 'does not contain the rule' do
          shell('ip6tables-save') do |r|
            expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m iprange --dst-range 2001::db8::1-2001:db8::ff -m multiport --ports 602 -m comment --comment "602 - test" -j ACCEPT})
          end
        end
      end
    end

    ['dst_type', 'src_type'].each do |type|
      describe type.to_s do
        context 'when BROKEN' do
          pp67 = <<-PUPPETCODE
              class { '::firewall': }
              firewall { '603 - test':
                proto    => tcp,
                action   => accept,
                #{type}  => 'BROKEN',
                provider => 'ip6tables',
              }
            PUPPETCODE
          it 'fails' do
            apply_manifest(pp67, expect_failures: true) do |r|
              expect(r.stderr).to match(%r{Invalid value "BROKEN".})
            end
          end

          it 'does not contain the rule' do
            shell('ip6tables-save') do |r|
              expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m addrtype\s.*\sBROKEN -m comment --comment "603 - test" -j ACCEPT})
            end
          end
        end

        context 'when duplicated LOCAL' do
          pp104 = <<-PUPPETCODE
                class { '::firewall': }
                firewall { '619 - test':
                  proto    => tcp,
                  action   => accept,
                  #{type}  => ['LOCAL', 'LOCAL'],
                  provider => 'ip6tables',
                }
            PUPPETCODE
          it 'fails' do
            apply_manifest(pp104, expect_failures: true) do |r|
              expect(r.stderr).to match(%r{#{type} elements must be unique})
            end
          end

          it 'does not contain the rule' do
            shell('ip6tables-save') do |r|
              expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m addrtype\s.*\sLOCAL -m addrtype\s.*\sLOCAL -m comment --comment "619 - test" -j ACCEPT})
            end
          end
        end

        context 'when multiple addrtype fail', if: (os[:family] == 'redhat' && os[:release].start_with?('5')) do
          pp106 = <<-PUPPETCODE
                class { '::firewall': }
                firewall { '616 - test':
                  proto    => tcp,
                  action   => accept,
                  #{type}  => ['LOCAL', '! LOCAL'],
                  provider => 'ip6tables',
                }
            PUPPETCODE
          it 'fails' do
            apply_manifest(pp106, expect_failures: true) do |r|
              expect(r.stderr).to match(%r{Multiple #{type} elements are available from iptables version})
            end
          end

          it 'does not contain the rule' do
            shell('ip6tables-save') do |r|
              expect(r.stdout).not_to match(%r{-A INPUT -p tcp -m addrtype --#{type.tr('_', '-')} LOCAL -m addrtype ! --#{type.tr('_', '-')} LOCAL -m comment --comment "616 - test" -j ACCEPT})
            end
          end
        end
      end
    end

    # ipset is hard to test, only testing on ubuntu 14
    describe 'ipset', if: (host_inventory['facter']['os']['name'] == 'Ubuntu' && os[:release].start_with?('14')) do
      before(:all) do
        pp = <<-PUPPETCODE
          exec { 'hackery pt 1':
            command => 'service iptables-persistent flush',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          }
          package { 'ipset':
            ensure  => present,
            require => Exec['hackery pt 1'],
          }
          exec { 'hackery pt 2':
            command => 'service iptables-persistent start',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            require => Package['ipset'],
          }
          class { '::firewall': }
          exec { 'create ipset blacklist':
            command => 'ipset create blacklist hash:ip,port family inet6 maxelem 1024 hashsize 65535 timeout 120',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            require => Package['ipset'],
          }
          -> exec { 'create ipset honeypot':
            command => 'ipset create honeypot hash:ip family inet6 maxelem 1024 hashsize 65535 timeout 120',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          }
          -> exec { 'add blacklist':
            command => 'ipset add blacklist 2001:db8::1,80',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          }
          -> exec { 'add honeypot':
            command => 'ipset add honeypot 2001:db8::5',
            path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
          }
          firewall { '612 - test':
            ensure   => present,
            chain    => 'INPUT',
            proto    => tcp,
            action   => drop,
            ipset    => ['blacklist src,dst', '! honeypot dst'],
            provider => 'ip6tables',
            require  => Exec['add honeypot'],
          }
        PUPPETCODE
        apply_manifest(pp, catch_failures: true)        
      end

      it 'contains the rule' do
        expect(result.stdout).to match(%r{-A INPUT -p tcp -m set --match-set blacklist src,dst -m set ! --match-set honeypot dst -m comment --comment "612 - test" -j DROP})
      end
    end

  end
end
