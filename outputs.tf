output "dn" {
  value       = aci_rest.fabricSpineP.id
  description = "Distinguished name of `fabricSpineP` object."
}

output "name" {
  value       = aci_rest.fabricSpineP.content.name
  description = "Spine switch profile name."
}
