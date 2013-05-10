# encoding: UTF-8

shared_examples 'WpItem::Vulnerable' do

  # 2 variables have to be set in the described class or subject:
  #   let(:vulns_file)     { }
  #   let(:expected_vulns) { } The expected Vulnerabilities when using vulns_file and vulns_xpath
  #
  # 1 variable is optional, used if supplied, otherwise subject.vulns_xpath is used
  #   let(:vulns_xpath)    { }

  describe '#vulnerabilities' do
    let(:empty_file) { MODELS_FIXTURES + '/wp_item/vulnerable/empty.xml' }

    before do
      stub_request(:get, /.*\/readme\.txt/i)
      stub_request(:get, /.*\/style\.css/i)
    end

    after do
      subject.vulns_file  = @vulns_file
      subject.vulns_xpath = vulns_xpath if defined?(vulns_xpath)

      result = subject.vulnerabilities
      result.should be_a Vulnerabilities
      result.should == @expected
    end

    context 'when the vulns_file is empty' do
      it 'returns an empty Vulnerabilities' do
        @vulns_file = empty_file
        @expected   = Vulnerabilities.new
      end
    end

    it 'returns the expected vulnerabilities' do
      @vulns_file = vulns_file
      @expected   = expected_vulns
    end
  end

  describe '#vulnerable_to?' do
    let(:version_orig) { '1.5.6' }
    let(:version_newer) { '1.6' }
    let(:version_older) { '1.0' }
    let(:newer) { Vulnerability.new('Newer', 'XSS', ['ref'], nil, version_newer) }
    let(:older) { Vulnerability.new('Older', 'XSS', ['ref'], nil, version_older) }
    let(:same) { Vulnerability.new('Same', 'XSS', ['ref'], nil, version_orig) }

    before do
      stub_request(:get, /.*\/readme\.txt/i).to_return(status: 200, body: "Stable Tag: #{version_orig}")
      stub_request(:get, /.*\/style\.css/i).to_return(status: 200, body: "Version: #{version_orig}")
    end

    context 'check basic version comparing' do
      it 'should return true' do
        subject.version.should == version_orig
        subject.vulnerable_to?(newer).should be_true
      end

      it 'should return false' do
        subject.version.should == version_orig
        subject.vulnerable_to?(older).should be_false
      end

      it 'should return false' do
        subject.version.should == version_orig
        subject.vulnerable_to?(same).should be_false
      end
    end

    context 'no version found in wp_item' do
      before do
        stub_request(:get, /.*\/readme\.txt/i).to_return(status: 404)
        stub_request(:get, /.*\/style\.css/i).to_return(status: 404)
      end

      it 'should return true because no version can be detected' do
        subject.vulnerable_to?(newer).should be_true
        subject.vulnerable_to?(older).should be_true
        subject.vulnerable_to?(same).should be_true
      end
    end
  end

end
