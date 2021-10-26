defmodule Mix.Tasks.Heroicons.Generate do
  use Mix.Task

  @shortdoc "Convert source SVG files into heex components. Run `git clone https://github.com/tailwindlabs/heroicons.git` first."
  def run(_) do
    Enum.each(["outline", "solid"], &loop_directory/1)

    Mix.Task.run("format")
  end

  defp loop_directory(folder) do
    src_path = "./heroicons/optimized/#{folder}/"
    namespace = "Heroicons.#{String.capitalize(folder)}"

    file_content = """
    defmodule Petal.#{namespace} do
      use Phoenix.Component
      @moduledoc \"\"\"
      Icon name can be the function or passed in as a type eg.
      <Petal.Heroicons.Solid.home class="w-6 h-6" />
      <Petal.Heroicons.Solid.render type="home" class="w-6 h-6" />

      <Petal.Heroicons.Outline.home class="w-6 h-6" />
      <Petal.Heroicons.Outline.render type="home" class="w-6 h-6" />
      \"\"\"

      def render(assigns) do
        icon_name = assigns.icon
        apply(__MODULE__, icon_name, [assigns])
      end

    """

    functions_content =
      src_path
      |> File.ls!()
      |> Enum.filter(&(Path.extname(&1) == ".svg"))
      |> Enum.map(&create_component(src_path, &1))
      |> Enum.join("\n\n")

    file_content =
      file_content <>
        functions_content <>
        """

        end
        """

    dest_path = "./lib/petal/icons/heroicons/#{folder}.ex"

    unless File.exists?(dest_path) do
      File.mkdir_p("./lib/petal/icons/heroicons")
    end

    File.write!(dest_path, file_content)
  end

  defp create_component(src_path, filename) do
    svg_content =
      File.read!(Path.join(src_path, filename))
      |> String.trim()
      |> String.replace(~r/<svg /, "<svg class={@class} ")

    build_component(filename, svg_content)
  end

  defp function_name(current_filename) do
    current_filename
    |> Path.basename(".svg")
    |> String.replace("-", "_")
  end

  defp build_component(filename, svg) do
    """
    def #{function_name(filename)}(assigns) do
      assigns = assign_new(assigns, :class, fn -> "h-6 w-6" end)

      ~H\"\"\"
      #{svg}
      \"\"\"
    end
    """
  end
end
