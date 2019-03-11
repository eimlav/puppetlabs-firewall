require 'spec_helper_acceptance'

describe 'firewall attribute testing, happy path', unless: (os[:family] == 'redhat' && os[:release].start_with?('5', '6')) || (os[:family] == 'sles') do
  before :all do
    iptables_flush_all_tables
    ip6tables_flush_all_tables
  end

  describe 'attributes test' do
    before(:all) do
      pp = <<-PUPPETCODE
        class { '::firewall': }
        firewall { '571 - test':
          ensure => present,
          proto => tcp,
          port   => '571',
          action => accept,
          hop_limit => '5',
          provider => 'ip6tables',
        }
        firewall { '576 - test':
          proto  => udp,
          table  => 'mangle',
          outiface => 'virbr0',
          chain  => 'POSTROUTING',
          dport => '68',
          jump  => 'CHECKSUM',
          checksum_fill => true,
          provider => ip6tables,
        }
        firewall { '587 - test':
          ensure => present,
          proto => tcp,
          port   => '587',
          action => accept,
          ishasmorefrags => true,
          provider => 'ip6tables',
        }
        firewall { '588 - test':
          ensure => present,
          proto => tcp,
          port   => '588',
          action => accept,
          ishasmorefrags => false,
          provider => 'ip6tables',
        }
        firewall { '589 - test':
          ensure => present,
          proto => tcp,
          port   => '589',
          action => accept,
          islastfrag => true,
          provider => 'ip6tables',
        }
        firewall { '590 - test':
          ensure => present,
          proto => tcp,
          port   => '590',
          action => accept,
          islastfrag => false,
          provider => 'ip6tables',
        }
        firewall { '591 - test':
          ensure => present,
          proto => tcp,
          port   => '591',
          action => accept,
          isfirstfrag => true,
          provider => 'ip6tables',
        }
        firewall { '592 - test':
          ensure => present,
          proto => tcp,
          port   => '592',
          action => accept,
          isfirstfrag => false,
          provider => 'ip6tables',
        }
        firewall { '593 - test':
          proto  => tcp,
          action => accept,
          tcp_flags => 'FIN,SYN ACK',
          provider => 'ip6tables',
        }
        firewall { '601 - test':
          proto     => tcp,
          port      => '601',
          action    => accept,
          src_range => '2001:db8::1-2001:db8::ff',
          provider  => 'ip6tables',
        }
        firewall { '602 - test':
          proto     => tcp,
          port      => '602',
          action    => accept,
          dst_range => '2001:db8::1-2001:db8::ff',
          provider  => 'ip6tables',
        }
        firewall { '604 - test':
          ensure      => present,
          source      => '2001:db8::1/128',
          mac_source  => '0A:1B:3C:4D:5E:6F',
          chain       => 'INPUT',
          provider    => 'ip6tables',
        }
        firewall { '605 - test':
          ensure   => present,
          proto    => tcp,
          port     => '605',
          action   => accept,
          chain    => 'INPUT',
          socket   => true,
          provider => 'ip6tables',
        }
        firewall { '606 - test':
          ensure   => present,
          proto    => tcp,
          port     => '606',
          action   => accept,
          chain    => 'INPUT',
          socket   => false,
          provider => 'ip6tables',
        }
        firewall { '607 - test':
          ensure       => 'present',
          action       => 'reject',
          chain        => 'OUTPUT',
          destination  => '2001:db8::1/128',
          ipsec_dir    => 'out',
          ipsec_policy => 'ipsec',
          proto        => 'all',
          reject       => 'icmp6-adm-prohibited',
          table        => 'filter',
          provider     => 'ip6tables',
        }
        firewall { '608 - test':
          ensure       => 'present',
          action       => 'reject',
          chain        => 'OUTPUT',
          destination  => '2001:db8::1/128',
          ipsec_dir    => 'out',
          ipsec_policy => 'none',
          proto        => 'all',
          reject       => 'icmp6-adm-prohibited',
          table        => 'filter',
          provider     => 'ip6tables',
        }
        firewall { '609 - test':
          ensure       => 'present',
          action       => 'reject',
          chain        => 'OUTPUT',
          destination  => '2001:db8::1/128',
          ipsec_dir    => 'out',
          ipsec_policy => 'ipsec',
          proto        => 'all',
          reject       => 'icmp6-adm-prohibited',
          table        => 'filter',
          provider     => 'ip6tables',
        }
        firewall { '610 - test':
          ensure       => 'present',
          action       => 'reject',
          chain        => 'INPUT',
          destination  => '2001:db8::1/128',
          ipsec_dir    => 'in',
          ipsec_policy => 'none',
          proto        => 'all',
          reject       => 'icmp6-adm-prohibited',
          table        => 'filter',
          provider     => 'ip6tables',
        }
        firewall { '611 - test':
          ensure => present,
          chain => 'OUTPUT',
          proto => tcp,
          port   => '611',
          jump => 'MARK',
          table => 'mangle',
          set_mark => '0x3e8/0xffffffff',
          provider => 'ip6tables',
        }
        firewall { '613 - test':
          proto    => tcp,
          action   => accept,
          dst_type  => 'MULTICAST',
          provider => 'ip6tables',
        }
        firewall { '614 - test':
          proto    => tcp,
          action   => accept,
          src_type  => 'MULTICAST',
          provider => 'ip6tables',
        }
        firewall { '615 - test inversion':
          proto    => tcp,
          action   => accept,
          dst_type  => '! MULTICAST',
          provider => 'ip6tables',
        }
        firewall { '616 - test inversion':
          proto    => tcp,
          action   => accept,
          src_type  => '! MULTICAST',
          provider => 'ip6tables',
        }
        firewall { '619 - test':
          proto    => tcp,
          action   => accept,
          dst_type  => ['LOCAL', '! LOCAL'],
          provider => 'ip6tables',
        }
        firewall { '620 - test':
          proto    => tcp,
          action   => accept,
          src_type  => ['LOCAL', '! LOCAL'],
          provider => 'ip6tables',
        }
        firewall { '801 - ipt_modules tests':
          proto              => tcp,
          dport              => '8080',
          action             => reject,
          chain              => 'OUTPUT',
          provider           => 'ip6tables',
          uid                => 0,
          gid                => 404,
          src_range          => "2001::-2002::",
          dst_range          => "2003::-2004::",
          src_type           => 'LOCAL',
          dst_type           => 'UNICAST',
          physdev_in         => "eth0",
          physdev_out        => "eth1",
          physdev_is_bridged => true,
        }
        firewall { '802 - ipt_modules tests':
          proto              => tcp,
          dport              => '8080',
          action             => reject,
          chain              => 'OUTPUT',
          provider           => 'ip6tables',
          gid                => 404,
          dst_range          => "2003::-2004::",
          dst_type           => 'UNICAST',
          physdev_out        => "eth1",
          physdev_is_bridged => true,
        }
        firewall { '811 - tee_gateway6':
          chain    => 'PREROUTING',
          table    => 'mangle',
          jump     => 'TEE',
          gateway  => '2001:db8::1',
          proto   => all,
          provider => 'ip6tables',
        }
        firewall { '805 - test':
          proto              => tcp,
          dport              => '8080',
          action             => accept,
          chain              => 'OUTPUT',
          date_start         => '2016-01-19T04:17:07',
          date_stop          => '2038-01-19T04:17:07',
          time_start         => '6:00',
          time_stop          => '17:00:00',
          month_days         => '7',
          week_days          => 'Tue',
          kernel_timezone    => true,
          provider           => 'ip6tables',
        }

      PUPPETCODE
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: do_catch_changes)
    end
    let(:result) { shell('ip6tables-save') }

    it 'hop_limit is set' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 571 -m hl --hl-eq 5 -m comment --comment "571 - test" -j ACCEPT})
    end
    it 'checksum_fill is set' do
      expect(result.stdout).to match(%r{-A POSTROUTING -o virbr0 -p udp -m multiport --dports 68 -m comment --comment "576 - test" -j CHECKSUM --checksum-fill})
    end
    it 'ishasmorefrags when true' do
      expect(result.stdout).to match(%r{A INPUT -p tcp -m frag --fragid 0 --fragmore -m multiport --ports 587 -m comment --comment "587 - test" -j ACCEPT})
    end
    it 'ishasmorefrags when false' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 588 -m comment --comment "588 - test" -j ACCEPT})
    end
    it 'islastfrag when true' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m frag --fragid 0 --fraglast -m multiport --ports 589 -m comment --comment "589 - test" -j ACCEPT})
    end
    it 'islastfrag when false' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 590 -m comment --comment "590 - test" -j ACCEPT})
    end
    it 'isfirstfrag when true' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m frag --fragid 0 --fragfirst -m multiport --ports 591 -m comment --comment "591 - test" -j ACCEPT})
    end
    it 'isfirstfrag when false' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 592 -m comment --comment "592 - test" -j ACCEPT})
    end
    it 'tcp_flags is set' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m tcp --tcp-flags FIN,SYN ACK -m comment --comment "593 - test" -j ACCEPT})
    end
    it 'src_range is set' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m iprange --src-range 2001:db8::1-2001:db8::ff -m multiport --ports 601 -m comment --comment "601 - test" -j ACCEPT})
    end
    it 'dst_range is set' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m iprange --dst-range 2001:db8::1-2001:db8::ff -m multiport --ports 602 -m comment --comment "602 - test" -j ACCEPT})
    end
    it 'mac_source is set' do
      expect(result.stdout).to match(%r{-A INPUT -s 2001:db8::1\/(128|ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff) -p tcp -m mac --mac-source 0A:1B:3C:4D:5E:6F -m comment --comment "604 - test"})
    end
    it 'socket when true' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 605 -m socket -m comment --comment "605 - test" -j ACCEPT})
    end
    it 'socket when false' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m multiport --ports 606 -m comment --comment "606 - test" -j ACCEPT})
    end
    it 'ipsec_policy when "ipsec"' do
      expect(result.stdout).to match(
        %r{-A OUTPUT -d 2001:db8::1\/(128|ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff) -m policy --dir out --pol ipsec -m comment --comment "607 - test" -j REJECT --reject-with icmp6-adm-prohibited}, # rubocop:disable Metrics/LineLength
      )
    end
    it 'ipsec_policy when "none"' do
      expect(result.stdout).to match(
        %r{-A OUTPUT -d 2001:db8::1\/(128|ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff) -m policy --dir out --pol none -m comment --comment "608 - test" -j REJECT --reject-with icmp6-adm-prohibited},
      )
    end
    it 'ipsec_dir when "out"' do
      expect(result.stdout).to match(
        %r{-A OUTPUT -d 2001:db8::1\/(128|ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff) -m policy --dir out --pol ipsec -m comment --comment "609 - test" -j REJECT --reject-with icmp6-adm-prohibited}, # rubocop:disable Metrics/LineLength
      )
    end
    it 'ipsec_dir when "in"' do
      expect(result.stdout).to match(
        %r{-A INPUT -d 2001:db8::1\/(128|ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff) -m policy --dir in --pol none -m comment --comment "610 - test" -j REJECT --reject-with icmp6-adm-prohibited},
      )
    end
    it 'set_mark is set' do
      expect(result.stdout).to match(%r{-A OUTPUT -p tcp -m multiport --ports 611 -m comment --comment "611 - test" -j MARK --set-xmark 0x3e8\/0xffffffff})
    end
    it 'dst_type when "MULTICAST"' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype\s--dst-type\sMULTICAST -m comment --comment "613 - test" -j ACCEPT})
    end
    it 'src_type when "MULTICAST"' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype\s--src-type\sMULTICAST -m comment --comment "614 - test" -j ACCEPT})
    end
    it 'dst_type when "! MULTICAST"' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype( !\s--dst-type\sMULTICAST|\s--dst-type\s! MULTICAST) -m comment --comment "615 - test inversion" -j ACCEPT})
    end
    it 'src_type when "! MULTICAST"' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype( !\s--src-type\sMULTICAST|\s--src-type\s! MULTICAST) -m comment --comment "616 - test inversion" -j ACCEPT})
    end
    it 'dst_type when multiple values' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype --dst-type LOCAL -m addrtype ! --dst-type LOCAL -m comment --comment "619 - test" -j ACCEPT})
    end
    it 'src_type when multiple values' do
      expect(result.stdout).to match(%r{-A INPUT -p tcp -m addrtype --src-type LOCAL -m addrtype ! --src-type LOCAL -m comment --comment "620 - test" -j ACCEPT})
    end
    it 'all the modules with multiple args is set' do
      expect(result.stdout).to match(%r{-A OUTPUT -p tcp -m physdev\s+--physdev-in eth0 --physdev-out eth1 --physdev-is-bridged -m iprange --src-range 2001::-2002::\s+--dst-range 2003::-2004:: -m owner --uid-owner (0|root) --gid-owner 404 -m multiport --dports 8080 -m addrtype --src-type LOCAL --dst-type UNICAST -m comment --comment "801 - ipt_modules tests" -j REJECT --reject-with icmp6-port-unreachable}) # rubocop:disable Metrics/LineLength
    end
    it 'all the modules with single args is set' do
      expect(result.stdout).to match(%r{-A OUTPUT -p tcp -m physdev\s+--physdev-out eth1 --physdev-is-bridged -m iprange --dst-range 2003::-2004:: -m owner --gid-owner 404 -m multiport --dports 8080 -m addrtype --dst-type UNICAST -m comment --comment "802 - ipt_modules tests" -j REJECT --reject-with icmp6-port-unreachable}) # rubocop:disable Metrics/LineLength
    end
    it 'tee_gateway is set' do
      expect(result.stdout).to match(%r{-A PREROUTING -m comment --comment "811 - tee_gateway6" -j TEE --gateway 2001:db8::1})
    end
    it 'when set all time parameters' do
      expect(result.stdout).to match(
        %r{-A OUTPUT -p tcp -m multiport --dports 8080 -m time --timestart 06:00:00 --timestop 17:00:00 --monthdays 7 --weekdays Tue --datestart 2016-01-19T04:17:07 --datestop 2038-01-19T04:17:07 --kerneltz -m comment --comment "805 - test" -j ACCEPT}, # rubocop:disable Metrics/LineLength
      )
    end
  end
end
