terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "netascode/aci"
      version = ">=0.2.0"
    }
  }
}

module "main" {
  source = "../.."

  name               = "SPINE1001"
  interface_profiles = ["PROF1"]
  selectors = [{
    name   = "SEL1"
    policy = "POL1"
    node_blocks = [{
      name = "BLOCK1"
      from = 1001
      to   = 1001
    }]
  }]
}

data "aci_rest" "fabricSpineP" {
  dn = "uni/fabric/spprof-${module.main.name}"

  depends_on = [module.main]
}

resource "test_assertions" "fabricSpineP" {
  component = "fabricSpineP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.fabricSpineP.content.name
    want        = module.main.name
  }
}

data "aci_rest" "fabricSpineS" {
  dn = "${data.aci_rest.fabricSpineP.id}/spines-SEL1-typ-range"

  depends_on = [module.main]
}

resource "test_assertions" "fabricSpineS" {
  component = "fabricSpineS"

  equal "name" {
    description = "name"
    got         = data.aci_rest.fabricSpineS.content.name
    want        = "SEL1"
  }
}

data "aci_rest" "fabricRsSpNodePGrp" {
  dn = "${data.aci_rest.fabricSpineS.id}/rsspNodePGrp"

  depends_on = [module.main]
}

resource "test_assertions" "fabricRsSpNodePGrp" {
  component = "fabricRsSpNodePGrp"

  equal "tDn" {
    description = "tDn"
    got         = data.aci_rest.fabricRsSpNodePGrp.content.tDn
    want        = "uni/fabric/funcprof/spnodepgrp-POL1"
  }
}

data "aci_rest" "fabricNodeBlk" {
  dn = "${data.aci_rest.fabricSpineS.id}/nodeblk-BLOCK1"

  depends_on = [module.main]
}


resource "test_assertions" "fabricNodeBlk" {
  component = "fabricNodeBlk"

  equal "name" {
    description = "name"
    got         = data.aci_rest.fabricNodeBlk.content.name
    want        = "BLOCK1"
  }

  equal "from_" {
    description = "from_"
    got         = data.aci_rest.fabricNodeBlk.content.from_
    want        = "1001"
  }

  equal "to_" {
    description = "to_"
    got         = data.aci_rest.fabricNodeBlk.content.to_
    want        = "1001"
  }
}

data "aci_rest" "fabricRsSpPortP" {
  dn = "${data.aci_rest.fabricSpineP.id}/rsspPortP-[uni/fabric/spportp-PROF1]"

  depends_on = [module.main]
}

resource "test_assertions" "fabricRsSpPortP" {
  component = "fabricRsSpPortP"

  equal "tDn" {
    description = "tDn"
    got         = data.aci_rest.fabricRsSpPortP.content.tDn
    want        = "uni/fabric/spportp-PROF1"
  }
}
