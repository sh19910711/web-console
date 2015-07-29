namespace :ext do
  rootdir = Pathname('extensions')

  desc 'Build Chrome Extension'
  task chrome: 'chrome:build'

  desc 'Build Firefox Add-on'
  task firefox: 'firefox:build'

  namespace :chrome do
    dist   = Pathname('dist/crx')
    extdir = rootdir.join(dist)
    manifest_json = rootdir.join('chrome/manifest.json')

    directory extdir

    task build: [ extdir, 'lib:templates' ] do
      cd rootdir do
        cp_r [ 'img/', 'tmp/lib/' ], dist
        `cd chrome && git ls-files`.split("\n").each do |src|
          dest = dist.join(src)
          mkdir_p dest.dirname
          cp Pathname('chrome').join(src), dest
        end
      end
    end

    # Generate a .crx file.
    task crx: [ :build, :npm ] do
      out = "crx-web-console-#{JSON.parse(File.read(manifest_json))["version"]}.crx"
      cd(extdir) { sh "node \"$(npm bin)/crx\" pack ./ -p ../crx-web-console.pem -o ../#{out}" }
    end

    # Generate a .zip file for Chrome Web Store.
    task zip: [ :build ] do
      version = JSON.parse(File.read(manifest_json))["version"]
      cd(extdir) { sh "zip -r ../crx-web-console-#{version}.zip ./" }
    end

    desc 'Launch a browser with the chrome extension.'
    task run: [ :build ] do
      cd(rootdir) { sh "sh ./script/run_chrome.sh --load-extension=#{dist}" }
    end
  end

  namespace :firefox do
    dist    = Pathname('dist/ffx')
    datadir = dist.join('data')
    extdir  = rootdir.join(dist)

    directory extdir

    task build: [ extdir, 'lib:templates' ] do
      cd(rootdir) do
        mkdir_p datadir
        cp_r [ 'tmp/lib/', 'img/' ], datadir
        `cd firefox && git ls-files`.split("\n").each do |src|
          dest = dist.join(src)
          mkdir_p dest.dirname
          cp Pathname('firefox').join(src), dest
        end
      end
    end

    task run: [ :npm, :build ] do
      jpm = nil
      cd(rootdir) { jpm = `printf $(npm bin)/jpm` }
      cd(extdir) { sh "JPM_FIREFOX_BINARY=`which firefox` node \"#{jpm}\" run" }
    end
  end

  task :npm do
    cd(rootdir) { sh "npm install --silent" }
  end

  namespace :lib do
    templates = Pathname('lib/web_console/templates')
    tmplib    = rootdir.join('tmp/lib/')
    js_erb    = FileList.new(templates.join('**/*.js.erb'))
    dirs      = js_erb.pathmap("%{^#{templates},#{tmplib}}d")

    task templates: dirs + js_erb.pathmap("%{^#{templates},#{tmplib}}X")

    dirs.each { |d| directory d }
    rule '.js' => [ "%{^#{tmplib},#{templates}}X.js.erb" ] do |t|
      File.write(t.name, WebConsole::Testing::ERBPrecompiler.new(t.source).build)
    end
  end
end
