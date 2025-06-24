def build_with_gradle(project_dir, build_type = "Debug")
  gradlew = File.join(project_dir, "gradlew")
  unless File.exist?(gradlew)
    raise "Gradlew file not exists."
  end

  system("chmod +x #{gradlew}")

  cmd = "#{gradlew} assemble#{build_type.capitalize}"
  Dir.chdir(project_dir) do
    puts "[+] Compiling with Gradle: #{cmd}"
    system(cmd) or abort("[-] Failed to compile APK with Gradle")
  end

  apk_path = Dir.glob("#{project_dir}/app/build/outputs/apk/#{build_type.downcase}/*.apk").first
  if apk_path
    puts "[✓] APK generated: #{apk_path}"
    return apk_path
  else
    raise "Failed to compile, no apk found."
  end
end

def compile(name)
  return build_with_gradle("websrcs/#{name}/")
end