# frozen_string_literal: true

require 'json'

module RakeEntry
  class Build
    def initialize(
      context,
      build_dir: nil,
      cache_dir: nil,
      boot_source: nil
    )
      @context = context
      @build_dir = build_dir || 'build'
      @cache_dir = cache_dir || ::File.join(@build_dir, 'cache')
      @boot_source = boot_source || 'startup_stm32f103x6.s'
    end

    def declare
      desc('test')
      task('test') do
        puts cmsis_gcc_support.inspect
      end

      boot_object_path = ::File.join(@cache_dir, '_boot.o')

      desc('test2')
      task('test2': [boot_object_path])

      file(::File.join(@build_dir, 'application.elf')) do |t|
      end

      file(boot_object_path => [::File.join(cmsis_gcc_support, @boot_source)]) do |t|
        ::FileUtils.mkdir_p(::File.dirname(t.name))
        sh "arm-none-eabi-as #{t.source} -o #{t.name}"
      end

      ::Dir['src/**/*.c'].map do |source_path|
        source_dir, source_name = ::File.split(source_path)
        target_dir = source_dir.sub(%r[\Asrc(?:/|\z)], '').then do |remaining|
          ::File.join(@cache_dir, remaining)
        end
        target_name = source_name.sub(/\.c\z/, '.o')
        target_path = ::File.join(target_dir, target_name)
        list_name = source_name.sub(/\.c\z/, '.lst')
        list_path = ::File.join(target_dir, list_name)
        d_name =  source_name.sub(/\.c\z/, '.d')
        d_path = ::File.join(target_dir, d_name)
        file(target_path => [source_path]) do |t|
          ::FileUtils.mkdir_p(::File.dirname(t.name))
          sh "arm-none-eabi-gcc -c #{cflags} -MMD -MP -MF\"#{d_path}\" -Wa,-a,-ad,-alms=#{list_path} #{t.source} -o #{t.name}"
        end
      end

      # $(CACHE_DIR)/$(BOOT_OBJECT): $(BOOT_SOURCE) | $(CACHE_DIR)
      # $(AS) $(ASFLAGS) $< -o $@

      file('a.txt') do |t|
        sh "touch #{t.name}"
      end
    end

    private

    def cmsis_gcc_support
      @cmsis_gcc_support ||= ::Dir['vendor/cmsis-f1/**/gcc'].then(&:first)
    end

    def cflags
      @cflags ||= "-mcpu=cortex-m3 -mthumb -DSTM32F103x6 #{include_paths.map do |p|
        "-I#{p}"
      end.join(' ')} -O2 -Wall -fdata-sections -ffunction-sections"
    end

    def include_paths
      @include_paths ||= [
        *::Dir['vendor/cmsis*/**/stm32f1xx.h'].map do |path|
          ::File.dirname(path)
        end,
        *::Dir['vendor/cmsis*/**/Core/**/cmsis_gcc.h'].map do |path|
          ::File.dirname(path)
        end,
      ].tap do |path|
        puts 'weett', path.inspect
      end
    end

    def desc(*args, **kwargs, &block)
      @context.call(:desc, *args, **kwargs, &block)
    end

    def task(*args, **kwargs, &block)
      @context.call(:task, *args, **kwargs, &block)
    end

    def file(*args, **kwargs, &block)
      @context.call(:file, *args, **kwargs, &block)
    end

    def sh(*args, **kwargs, &block)
      @context.call(:sh, *args, **kwargs, &block)
    end
  end
end
