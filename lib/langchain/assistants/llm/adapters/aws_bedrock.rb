module Langchain
  class Assistant
    module LLM
      module Adapters
        class AwsBedrock < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
            end
            params[:system] = instructions if instructions
            params
          end

          def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
            warn "Image URL is not supported by AWS Bedrock currently" if image_url

            Langchain::Messages::AwsBedrockMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call["id"]
            function_name = tool_call["function"]["name"]
            tool_name, method_name = function_name.split("__")
            tool_arguments = JSON.parse(tool_call["function"]["arguments"], symbolize_names: true)
            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_aws_bedrock_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool["name"] }
          end

          private

          def build_tool_choice(choice)
            case choice
            when "auto"
              "auto"
            when "none"
              "none"
            else
              {"name" => choice}
            end
          end
        end
      end
    end
  end
end