# Copyright (C) 2004-2006 Masao Mutoh, Laurent Sansonetti, Joseph Method

config = {'data-dir' => '/usr/share/alexandria', 'rb-dir' => '/usr/bin/ruby/1.8'}

# Generates config.rb.
File.open('lib/alexandria/config.rb', 'w') do |file|
    file.print <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.

module Alexandria
    module Config
        MAIN_DATA_DIR = '#{config['data-dir']}'
        DATA_DIR = '#{config['data-dir']}/alexandria'
        LIB_DIR = '#{config['rb-dir']}'
    end
end
EOS
end

# Generates version.rb.
File.open('lib/alexandria/version.rb', 'w') do |file|
    begin
        version = IO.readlines('VERSION').join
    rescue Errno::ENOENT
        version = "CVS"
    end
    file.print <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.

module Alexandria
    VERSION = "#{version}"
end
EOS
end

# Generates default_preferences.rb.
require 'rexml/document'

SCHEMA_PATH = 'schemas/alexandria.schemas'

def convert_with_type(value, type)
    case type
        when 'int'
            value.to_i
        when 'float'
            value.to_f
        when 'bool'
            value == 'true'
        else
            value.strip
    end
end

generated_lines = []

doc = REXML::Document.new(IO.read(SCHEMA_PATH))
doc.elements.each('gconfschemafile/schemalist/schema') do |element|
    default = element.elements['default'].text
    next unless default
    varname = File.basename(element.elements['key'].text)
    type = element.elements['type'].text

    if type == 'list' or type == 'pair'
        ary = default[1..-2].split(',')
        next if ary.empty?
        if type == 'list'
            list_type = element.elements['list_type'].text
            ary.map! { |x| convert_with_type(x, list_type) }
        elsif type == 'pair'
            next if ary.length != 2
            ary[0] = convert_with_type(ary[0], 
                                       element.elements['car_type'].text)
            ary[1] = convert_with_type(ary[1], 
                                       element.elements['cdr_type'].text)
        end
        default = ary.inspect
    else
        default = convert_with_type(default, type).inspect.to_s
    end

    generated_lines << varname.inspect + '=>' + default
end

default_preferences = <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.
EOS

File.open('lib/alexandria/default_preferences.rb', 'w') do |file|
    file.print <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.

module Alexandria
    class Preferences
        DEFAULT_VALUES = {#{generated_lines.join(',')}}
    end
end
EOS
end