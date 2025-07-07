class_name ProjectileBehaviorFactory
extends Resource

static func create_behavior(sauce_resource: BaseSauceResource) -> ProjectileBehavior:
	match sauce_resource.special_effect_type:
		BaseSauceResource.SpecialEffectType.PIERCE:
			return PierceBehavior.new()
		#BaseSauceResource.SpecialEffectType.BOUNCE:
			#return BounceBehavior.new()
		#BaseSauceResource.SpecialEffectType.QUANTUM:
			#return QuantumBehavior.new()
		_:
			return StandardBehavior.new()
