
output "bedrock_knowledge_base_id" {
  description = "The unique ID of the Bedrock Knowledge Base."
  value       = module.bedrock_kb.id
}

output "bedrock_knowledge_base_arn" {
  description = "The ARN of the Bedrock Knowledge Base."
  value       = module.bedrock_kb.arn
}
