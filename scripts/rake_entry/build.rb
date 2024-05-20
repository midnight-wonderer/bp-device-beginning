# frozen_string_literal: true

require 'json'

module RakeEntry
  class Build
    def initialize(
      context,
      build_dir: nil,
      cache_dir: nil,
      c_defs: %w[STM32F103x6],
      boot_source: 'startup_stm32f103x6.s',
      linker_script: 'STM32F103X6_FLASH.ld'
    )
      @context = context
      @build_dir = build_dir || 'build'
      @cache_dir = cache_dir || ::File.join(@build_dir, 'cache')
      @boot_source = boot_source
      @c_defs = c_defs
      @linker = linker_script
    end

    def declare
      boot_object_path = ::File.join(@cache_dir, '_boot.o')
      application_elf = ::File.join(@build_dir, 'application.elf')
      application_map_file = ::File.join(@build_dir, 'application.map')
      application_ar = ::File.join(@cache_dir, 'libapplication.a')

      file(application_elf => [boot_object_path, application_ar, ::File.join(cmsis_gcc_support, 'linker', @linker)]) do |t|
        boot, ar, ld = t.prerequisites
        lib_dir, lib_file = ::File.split(ar)
        lib_name = /\Alib(\w+)\.a\z/.match(lib_file).then do |matched|
          matched[1]
        end
        [
          "arm-none-eabi-gcc #{boot} -mcpu=cortex-m3 -mthumb -specs=nano.specs",
          "-T#{ld} -L#{lib_dir} -lc -lm -lnosys -Wl,--gc-sections",
          "-Wl,-Map=#{application_map_file},--cref",
          "-l#{lib_name}",
          "-o #{t.name}",
        ].join(' ').tap do |command|
          sh command
        end
        sh "arm-none-eabi-size #{t.name}"
      end

      file(boot_object_path => [::File.join(cmsis_gcc_support, @boot_source)]) do |t|
        ::FileUtils.mkdir_p(::File.dirname(t.name))
        sh "arm-none-eabi-as #{t.source} -o #{t.name}"
      end

      application_map = ::Dir['src/**/*.c'].map do |source_path|
        source_dir, source_name = ::File.split(source_path)
        target_dir = source_dir.sub(%r[\Asrc(?:/|\z)], '').then do |remaining|
          ::File.join(@cache_dir, remaining)
        end
        target_name = source_name.sub(/\.c\z/, '.o')
        target_path = ::File.join(target_dir, target_name)
        list_name = source_name.sub(/\.c\z/, '.lst')
        list_path = ::File.join(target_dir, list_name)
        d_name = source_name.sub(/\.c\z/, '.d')
        d_path = ::File.join(target_dir, d_name)
        { source_path: source_path, target_path: target_path, list_path: list_path, d_path: d_path }
      end

      application_map.each do |entry|
        source_path, target_path, list_path, d_path = entry.values_at(:source_path, :target_path, :list_path, :d_path)
        file(target_path => [source_path]) do |t|
          ::FileUtils.mkdir_p(::File.dirname(t.name))
          sh "arm-none-eabi-gcc -c #{cflags} -MMD -MP -MF\"#{d_path}\" -Wa,-a,-ad,-alms=#{list_path} #{t.source} -o #{t.name}"
        end
      end

      application_map.map do |entry|
        entry[:target_path]
      end.tap do |application_objects|
        file(application_ar => application_objects) do |t|
          ::FileUtils.mkdir_p(::File.dirname(t.name))
          sh "arm-none-eabi-ar rcs #{t.name} #{t.prerequisites.join(' ')}"
        end
      end
    end

    private

    def cmsis_gcc_support
      @cmsis_gcc_support ||= ::Dir['vendor/cmsis-f1/**/gcc'].then(&:first)
    end

    def cflags
      @cflags ||= begin
        def_flags = @c_defs.map do |d|
          "-D#{d}"
        end.join(' ')
        include_options = include_paths.map do |p|
          "-I#{p}"
        end.join(' ')
        "-mcpu=cortex-m3 -mthumb #{def_flags} #{include_options} -O2 -Wall -fdata-sections -ffunction-sections"
      end
    end

    def include_paths
      @include_paths ||= [
        *::Dir['vendor/cmsis*/**/Core/**/cmsis_gcc.h'],
        *::Dir['vendor/cmsis*/**/stm32f1xx.h'],
      ].map do |path|
        ::File.dirname(path)
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
