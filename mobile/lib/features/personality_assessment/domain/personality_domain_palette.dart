/// Identidade dos fatores do NEO PI-R, independente do toolkit de UI.
enum PersonalityDomainTone { red, amber, green, purple, blue }

const personalityDomainPalette = <String, PersonalityDomainTone>{
  'neuroticism': PersonalityDomainTone.red,
  'extraversion': PersonalityDomainTone.amber,
  'openness': PersonalityDomainTone.green,
  'agreeableness': PersonalityDomainTone.purple,
  'conscientiousness': PersonalityDomainTone.blue,
};
