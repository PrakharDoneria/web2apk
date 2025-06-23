require "json"
require "open-uri"
require "sinatra"
require "zip"
require "fileutils"

require "./compile.rb"
require "./upload.rb"

get "/" do
  "@by Aquiles Trindade (trindadedev)"
end

post "/to_apk" do
  content_type :json

  begin
    payload = JSON.parse(request.body.read)
    url = payload["file"]
    uri = URI.parse(url)

    raise "Invalid URL" unless uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS)

    filename = File.basename(uri.path)
    base_name = filename.sub(/\.zip$/, "")
    zip_path = "websrcs/#{base_name}_temp.zip"
    extract_dir = "websrcs/#{base_name}"

    FileUtils.mkdir_p("websrcs")

    # download
    File.write(zip_path, URI.open(url).read)

    # extract
    FileUtils.mkdir_p(extract_dir)
    puts zip_path
    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        dest_path = File.join(extract_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(dest_path))
        zip_file.extract(entry, dest_path) unless File.exist?(dest_path)
      end
    end

    # compile & upload
    apk_file = compile(filename)
    apk_url = upload(apk_file)

    # clean
    File.delete(apk_file) if File.exist?(apk_file)
    FileUtils.rm_rf(extract_dir)
    File.delete(zip_path) if File.exist?(zip_path)

    { status: "ok", result: apk_url }.to_json
  rescue => e
    status 400
    { status: "error", message: e.message }.to_json
  end
end