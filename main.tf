locals {
  spine_interface_profiles = [for v in var.interface_profiles : "uni/fabric/spportp-${v}"]
  node_blocks = flatten([
    for selector in var.selectors : [
      for node_block in selector.node_blocks : {
        key = "${selector.name}/${node_block.name}"
        value = {
          selector_rn = "spines-${selector.name}-typ-range"
          name        = node_block.name
          from        = node_block.from
          to          = lookup(node_block, "to", node_block.from)
        }
      }
    ]
  ])
}

resource "aci_rest" "fabricSpineP" {
  dn         = "uni/fabric/spprof-${var.name}"
  class_name = "fabricSpineP"
  content = {
    name = var.name
  }
}

resource "aci_rest" "fabricSpineS" {
  for_each   = { for selector in var.selectors : selector.name => selector }
  dn         = "${aci_rest.fabricSpineP.id}/spines-${each.value.name}-typ-range"
  class_name = "fabricSpineS"
  content = {
    name = each.value.name
    type = "range"
  }
}

resource "aci_rest" "fabricRsSpNodePGrp" {
  for_each   = { for selector in var.selectors : selector.name => selector if selector.policy != null }
  dn         = "${aci_rest.fabricSpineS[each.value.name].id}/rsspNodePGrp"
  class_name = "fabricRsSpNodePGrp"
  content = {
    tDn = "uni/fabric/funcprof/spnodepgrp-${each.value.policy}"
  }
}

resource "aci_rest" "fabricNodeBlk" {
  for_each   = { for item in local.node_blocks : item.key => item.value }
  dn         = "${aci_rest.fabricSpineP.id}/${each.value.selector_rn}/nodeblk-${each.value.name}"
  class_name = "fabricNodeBlk"
  content = {
    name  = each.value.name
    from_ = each.value.from
    to_   = each.value.to
  }
  depends_on = [
    aci_rest.fabricSpineS
  ]
}

resource "aci_rest" "fabricRsSpPortP" {
  for_each   = toset(local.spine_interface_profiles)
  dn         = "${aci_rest.fabricSpineP.id}/rsspPortP-[${each.value}]"
  class_name = "fabricRsSpPortP"
  content = {
    tDn = each.value
  }
}
