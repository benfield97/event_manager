require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody'])

        legislators = legislators.officials

    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def clean_phone_number(number)
    number = number.to_s.gsub(/[^0-9]/, "")
    if number.length == 10
        number
    elsif number.length == 11 && number[0] == "1"
        number[1..-1]
    else
        "0000000000"
    end
end
def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_time(time)
    time = DateTime.strptime(time, '%m/%d/%y %H:%M')
    time.strftime("%H")

    if time.hour < 12
        time = "#{time.hour} AM"
    else
        time = "#{time.hour - 12} PM"
    end
end

def clean_day(day)
    day = DateTime.strptime(day, '%m/%d/%y %H:%M')
    day.strftime("%A")
end

puts "Event manager Initialized!"

contents = CSV.open('event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


hours_count = Hash.new(0)
day_count = Hash.new(0)


contents.each do |row|
    name = row[:first_name]
    #zipcode = row[:zipcode]
    number = row[:homephone]

    reg_time = row[:regdate]
    day = clean_day(reg_time)
    puts day
    reg_time = clean_time(reg_time)
    puts reg_time
    hours_count[reg_time] += 1
    day_count[day] += 1

    zipcode = clean_zipcode(zipcode)

    number = clean_phone_number(number)
    puts number
    
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
end 


most_common_times = hours_count.max_by(3) { |_, count| count }.to_h
most_common_days = day_count.max_by(3) { |_, count| count }.to_h

puts most_common_times, most_common_days




