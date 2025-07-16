# Resources/Behaviors/projectile_behavior_factory.gd
class_name ProjectileBehaviorFactory
extends Resource

static func create_behavior(sauce_resource: BaseSauceResource) -> ProjectileBehavior:
	# First check pierce_count stat (modern method)
	if sauce_resource.pierce_count > 0:
		return PierceBehavior.new()

	# Then check special effect type (legacy/talent method)
	match sauce_resource.special_effect_type:
		#BaseSauceResource.SpecialEffectType.PIERCE:
			#pass
			#return PierceBehavior.new()
		#BaseSauceResource.SpecialEffectType.BOUNCE:
			#return BounceBehavior.new()
		#BaseSauceResource.SpecialEffectType.QUANTUM:
			#return QuantumBehavior.new()
		_:
			return StandardBehavior.new()
