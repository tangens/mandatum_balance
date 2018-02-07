require "bundler/inline"

# TODO: Not print gems fetching data
gemfile(install: true) do
  source 'https://rubygems.org'
  gem 'mechanize', '2.7.5', require: true
end

if !(ENV["MANDATUM_AGREEMENT_NUMBER"] && ENV["MANDATUM_PCODE_LAST_PART"] && ENV["MANDATUM_PASSWORD"])
  puts "================== ERROR ========================="
  ["MANDATUM_AGREEMENT_NUMBER", "MANDATUM_PCODE_LAST_PART", "MANDATUM_PASSWORD"].each do |attribute|
    puts "#{attribute} missing" unless ENV[attribute]
  end
  puts "=================================================="
else
  mechanize = Mechanize.new

  mechanize.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  mechanize.get('https://medical.mandatumlife.lv/csvp/lv/users/login') do |page|
    search_result = page.form_with(:id => 'login-form') do |form|
      form.fields.each_with_index do |field, i|
        break if i > 2

        value =
          case i
          when 0
            ENV["MANDATUM_AGREEMENT_NUMBER"]
          when 1
            ENV["MANDATUM_PCODE_LAST_PART"]
          else
            ENV["MANDATUM_PASSWORD"]
          end

        form.send(field.name, value)
      end
    end.submit

    puts "============================================"
    if search_result.search('strong.value').length.positive?
      search_result.search('strong.value').each_with_index do |nokogiri_element, i|
        human_prefix =
          case i
          when 0
            'BALANCE: '
          when 1
            'UPDATED AT: '
          else
            ''
          end
        puts "#{human_prefix} #{nokogiri_element.content}"
      end
    else
      puts "NO DATA RECEIVED!"
    end
    puts "============================================"
  end
end
