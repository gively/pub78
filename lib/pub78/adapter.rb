module Pub78
  class Adapter
    IRS_URL = "http://www.irs.gov/pub/irs-soi/pub78ein.exe"
  
    def initialize(stream, updated_date)
      @stream = stream
      @updated_date = updated_date
    end
    
    def self.with_file(filename, &block)
      File.open(filename) do |io|
        yield Pub78::Adapter.new(io, File.mtime(filename))
      end
    end
    
    def self.with_zipfile(filename, &block)
      Zip::ZipInputStream::open(filename) do |io|
        while entry = io.get_next_entry
          if entry.file? && entry.name =~ /pub78ein\.txt$/i
            entry.get_input_stream do |input|
              yield Pub78::Adapter.new(input, entry.mtime)
            end
          end
        end
      end
    end
    
    # Awful hack: IRS gives us self-extracting ZIP files made with WinZip.  These contain
    # a ZIP file.  We just scan for the ZIP header and extract it out to a temporary
    # file.
    def self.with_exe(filename, &block)
      File.open(filename, 'rb', :encoding => "ascii-8bit") do |io|
        last4bytes = []
        Rails.logger.debug("Scanning #{filename} for ZIP header")
        while true
          last4bytes << io.read(1)
          last4bytes.shift while last4bytes.size > 4
          
          if (last4bytes[0] == "\x50" && last4bytes[1] == "\x4b" && 
              last4bytes[2] == "\x03" && last4bytes[3] == "\x04")
              
            Tempfile.open('pub78zip', :encoding => "ascii-8bit") do |tf|
              Rails.logger.debug("Extracting ZIP file to #{tf.path}")
              tf.write(last4bytes.join(""))
              io.seek(-4, IO::SEEK_CUR)
              IO.copy_stream(io, tf)

              with_zipfile(tf.path, &block)
            end
            
            break
          end        
        end
      end
    end
    
    def self.irs_update_time
      Time.httpdate(HTTPClient.new.head(IRS_URL).header['Last-Modified'][0])
    end
    
    def self.with_irs_data(min_date=nil, &block)
      if min_date
        Rails.logger.debug("Checking last update of IRS data")
        return unless irs_update_time > min_date
      end
      
      Tempfile.open('irs_pub78_data', :encoding => "ascii-8bit") do |tf|
        Rails.logger.debug("Downloading IRS data to #{tf.path}")
        HTTPClient.new.get_content(IRS_URL) do |chunk|
          tf.write(chunk)
        end
        
        with_exe(tf.path, &block)
      end
    end
    
    def each_line
      @stream.each_line do |line|
        yield line
      end
    end
    
    def parse_record(line)
      {
        :ein => sprintf("%s-%s", line.slice(0..1), line.slice(2..8)),
        :name => line.slice(10..115).strip,
        :address_city => line.slice(116..146).strip,
        :address_state => line.slice(147..148),
        :deductibility_codes => line.slice(150, line.length).strip,
        :is_pub78_verified => true,
        :pub78_date => @updated_date
      }
    end
    
    def timestamp_column_name
      :pub78_updated_at
    end
    
    def each_record
      each_line do |line|
        yield parse_record(line)
      end
    end
  end
end
