require 'rubygems'
require 'bundler/setup'
require 'stringex'

public_dir      = 'public'    # compiled site directory
source_dir      = 'source'    # source file directory
stash_dir       = '_stash'    # directory to stash posts for speedy generation
posts_dir       = '_posts'    # directory for blog files
themes_dir      = '.themes'   # directory for blog files
new_post_ext    = 'markdown'  # default new post file extension when using the new_post task
new_page_ext    = 'markdown'  # default new page file extension when using the new_page task

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  puts '## Set the codepage to 65001 for Windows machines'
  `cmd /c chcp 65001`
end

task :default do
  system 'rake --tasks'
end

#######################
# Working with Jekyll #
#######################

desc 'Generate jekyll site'
task :generate do
  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
  puts '## Generating Site with Jekyll'
  system 'compass compile'
  system('bundle exec jekyll build') || abort('An error occurred generating the site.')
end

# usage rake new_post[my-new-post] or rake new_post['my new post'] or rake new_post (defaults to "new-post")
desc "Begin a new post in #{source_dir}/#{posts_dir}"
task :new_post, :title do |_t, args|
  title = if args.title
            args.title
          else
            get_stdin('Enter a title for your post: ')
          end
  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
  mkdir_p "#{source_dir}/#{posts_dir}"
  filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
  if File.exist?(filename)
    abort('rake aborted!') if ask("#{filename} already exists. Do you want to overwrite?", %w[y n]) == 'n'
  end
  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts '---'
    post.puts 'layout: post'
    post.puts "title: \"#{title.gsub(/&/, '&amp;').gsub(/"/, '\\"')}\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    post.puts 'comments: true'
    post.puts 'categories: '
    post.puts '---'
  end
end

# usage rake new_page[my-new-page] or rake new_page[my-new-page.html] or rake new_page (defaults to "new-page.markdown")
desc "Create a new page in #{source_dir}/(filename)/index.#{new_page_ext}"
task :new_page, :filename do |_t, args|
  raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
  args.with_defaults(filename: 'new-page')
  page_dir = [source_dir]
  if args.filename.downcase =~ /(^.+\/)?(.+)/
    filename, _, extension = Regexp.last_match(2).rpartition('.').reject(&:empty?) # Get filename and extension
    title = filename
    page_dir.concat(Regexp.last_match(1).downcase.sub(/^\//, '').split('/')) unless Regexp.last_match(1).nil? # Add path to page_dir Array
    if extension.nil?
      page_dir << filename
      filename = 'index'
    end
    extension ||= new_page_ext
    page_dir = page_dir.map! { |d| _ = d.to_url }.join('/') # Sanitize path
    filename = filename.downcase.to_url

    mkdir_p page_dir
    file = "#{page_dir}/#{filename}.#{extension}"
    if File.exist?(file)
      abort('rake aborted!') if ask("#{file} already exists. Do you want to overwrite?", %w[y n]) == 'n'
    end
    puts "Creating new page: #{file}"
    open(file, 'w') do |page|
      page.puts '---'
      page.puts 'layout: page'
      page.puts "title: \"#{title}\""
      page.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M')}"
      page.puts 'comments: true'
      page.puts 'sharing: true'
      page.puts 'footer: true'
      page.puts '---'
    end
  else
    puts "Syntax error: #{args.filename} contains unsupported characters"
  end
end

# usage rake isolate[my-post]
desc 'Move all other posts than the one currently being worked on to a temporary stash location (stash) so regenerating the site happens much more quickly.'
task :isolate, :filename do |_t, args|
  stash_dir = "#{source_dir}/#{stash_dir}"
  FileUtils.mkdir(stash_dir) unless File.exist?(stash_dir)
  Dir.glob("#{source_dir}/#{posts_dir}/*.*") do |post|
    FileUtils.mv post, stash_dir unless post.include?(args.filename)
  end
end

desc 'Move all stashed posts back into the posts directory, ready for site generation.'
task :integrate do
  FileUtils.mv Dir.glob("#{source_dir}/#{stash_dir}/*.*"), "#{source_dir}/#{posts_dir}/"
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

desc 'list tasks'
task :list do
  if verbose == true
    system 'rake -T'
  else
    puts "Tasks: #{(Rake::Task.tasks - [Rake::Task[:list]]).join(', ')}"
    puts "(use -v or --verbose for more detail)\n\n"
  end
end

task default: [:list]
