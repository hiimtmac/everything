generate-openapi:
	@rm -rf Sources/OpenAPIShared/GeneratedSources Sources/OpenAPIServer/GeneratedSources Sources/OpenAPIClient/GeneratedSources
	@mkdir -p Sources/OpenAPIShared/GeneratedSources Sources/OpenAPIServer/GeneratedSources Sources/OpenAPIClient/GeneratedSources
	@swift package --allow-writing-to-package-directory generate-code-from-openapi OpenAPIShared
	@swift package --allow-writing-to-package-directory generate-code-from-openapi OpenAPIServer
	@swift package --allow-writing-to-package-directory generate-code-from-openapi OpenAPIClient

generate-grpc:
	@rm -rf Sources/GRPCShared/GeneratedSources Sources/GRPCClient/GeneratedSources Sources/GRPCServer/GeneratedSources
	@mkdir -p Sources/GRPCShared/GeneratedSources Sources/GRPCClient/GeneratedSources Sources/GRPCServer/GeneratedSources
	@swift package --allow-writing-to-package-directory generate-grpc-code-from-protos --output-path Sources/GRPCShared/GeneratedSources --file-naming dropPath --access-level public --no-servers --no-clients -- Sources/GRPCShared/proto
	@swift package --allow-writing-to-package-directory generate-grpc-code-from-protos --output-path Sources/GRPCClient/GeneratedSources --file-naming dropPath --access-level public --no-servers --no-messages -- Sources/GRPCClient/proto
	@swift package --allow-writing-to-package-directory generate-grpc-code-from-protos --output-path Sources/GRPCServer/GeneratedSources --file-naming dropPath --access-level public --no-clients --no-messages -- Sources/GRPCServer/proto
	@sed -i '' 's/import GRPCProtobuf/import GRPCProtobuf\nimport GRPCShared/' Sources/GRPCClient/GeneratedSources/*.swift
	@sed -i '' 's/import GRPCProtobuf/import GRPCProtobuf\nimport GRPCShared/' Sources/GRPCServer/GeneratedSources/*.swift

generate: generate-openapi generate-grpc

.PHONY: generate-openapi generate-grpc generate