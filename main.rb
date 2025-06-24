require "json"
require "open-uri"
require "sinatra"
require "zip"
require "fileutils"
require "nokogiri" # For XML handling, add 'nokogiri' gem to your dependencies

require "./compile.rb"
require "./upload.rb"

set :bind, '0.0.0.0'
set :port, ENV['PORT'] || 4567
set :protection, except: :host_authorization

# --- CORS Support ---
before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept, Authorization, X-Requested-With'
end

options '*' do
  200
end
# --- End CORS Support ---

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

    # ---- Optional Customization ----
    # Custom app name (optional)
    if payload["app_name"] && !payload["app_name"].strip.empty?
      strings_xml = File.join(extract_dir, "app/src/main/res/values/strings.xml")
      if File.exist?(strings_xml)
        doc = Nokogiri::XML(File.read(strings_xml))
        app_name_element = doc.at_xpath("//string[@name='app_name']")
        if app_name_element
          app_name_element.content = payload["app_name"]
          File.write(strings_xml, doc.to_xml)
        end
      end
    end

    # Custom package name (optional)
    if payload["package_name"] && !payload["package_name"].strip.empty?
      manifest_xml = File.join(extract_dir, "app/src/main/AndroidManifest.xml")
      if File.exist?(manifest_xml)
        doc = Nokogiri::XML(File.read(manifest_xml))
        manifest = doc.at_xpath("/manifest")
        if manifest && manifest["package"]
          old_package = manifest["package"]
          manifest["package"] = payload["package_name"]
          File.write(manifest_xml, doc.to_xml)

          # Optionally, rename Java/Kotlin source folders to match new package
          old_path = File.join(extract_dir, "app/src/main/java", *old_package.split('.'))
          new_path = File.join(extract_dir, "app/src/main/java", *payload["package_name"].split('.'))
          if File.exist?(old_path)
            FileUtils.mkdir_p(File.dirname(new_path))
            FileUtils.mv(old_path, new_path)
          end
        end
      end
    end

    # Custom version (optional)
    if payload["version"] && !payload["version"].strip.empty?
      build_gradle = File.join(extract_dir, "app/build.gradle")
      if File.exist?(build_gradle)
        gradle_text = File.read(build_gradle)
        # Simple regex replacements for versionName and versionCode
        gradle_text.gsub!(/versionName\s+"[^"]+"/, "versionName \"#{payload["version"]}\"")
        # Optionally allow versionCode to be set (must be integer)
        if payload["version_code"] && payload["version_code"].to_s.strip.match?(/^\d+$/)
          gradle_text.gsub!(/versionCode\s+\d+/, "versionCode #{payload["version_code"]}")
        end
        File.write(build_gradle, gradle_text)
      end
    end

    # Custom app icon (optional, expects 'icon' as BASE64 string or as a URL)
    if payload["icon"] && !payload["icon"].strip.empty?
      require "base64"
      icon_data = nil
      if payload["icon"] =~ /^https?:\/\//
        icon_data = URI.open(payload["icon"]).read
      else
        icon_data = Base64.decode64(payload["icon"])
      end
      # Replace all mipmap icons (assumes PNG)
      Dir.glob(File.join(extract_dir, "app/src/main/res/mipmap-*", "ic_launcher.png")).each do |icon_path|
        File.write(icon_path, icon_data)
      end
    end
    # ---- End Optional Customization ----

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
