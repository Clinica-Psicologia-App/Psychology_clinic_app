class PersonalityReferenceFacet {
  const PersonalityReferenceFacet({
    required this.name,
    required this.description,
    required this.lowScoreGuidance,
    required this.highScoreGuidance,
  });

  final String name;
  final String description;
  final String lowScoreGuidance;
  final String highScoreGuidance;
}

class PersonalityReferenceFactor {
  const PersonalityReferenceFactor({
    required this.name,
    required this.description,
    required this.facets,
  });

  final String name;
  final String description;
  final List<PersonalityReferenceFacet> facets;
}

const personalityReferenceNote =
    'Essas condutas visam trabalhar os esquemas subjacentes que influenciam '
    'o comportamento, ajudando os pacientes/clientes a desenvolverem uma '
    'compreensão mais profunda de suas reações e a promoverem mudanças positivas.';

const personalityReferenceFactors = <PersonalityReferenceFactor>[
  PersonalityReferenceFactor(
    name: 'Neuroticismo X Estabilidade emocional',
    description:
        'Contrasta o ajustamento versus o desajustamento emocional; avalia a suscetibilidade ao estresse e como uma pessoa reage diante das situações de pressão.',
    facets: [
      PersonalityReferenceFacet(
        name: 'Ansiedade',
        description:
            'Refere-se à sensação de apreensão, medo, tensão e preocupação excessiva.',
        lowScoreGuidance:
            'Explorar a relação com situações que geram ansiedade, promovendo estratégias para aumentar a conscientização sobre as emoções e os limites pessoais.',
        highScoreGuidance:
            'Trabalhar na identificação de esquemas de medo e insegurança. Promover técnicas de enfrentamento, como a reestruturação cognitiva para desafiar pensamentos distorcidos.',
      ),
      PersonalityReferenceFacet(
        name: 'Raiva/hostilidade',
        description:
            'Relaciona-se à tendência de vivenciar raiva e emoções associadas, como frustração e amargura.',
        lowScoreGuidance:
            'Focar em construir assertividade e estratégias para expressar necessidades e frustrações sem evitar o conflito.',
        highScoreGuidance:
            'Identificar esquemas de abandono ou desconfiança. Implementar técnicas de regulação emocional e desenvolver formas construtivas de expressar raiva.',
      ),
      PersonalityReferenceFacet(
        name: 'Depressão',
        description: 'Envolve uma propensão a experimentar afetos negativos.',
        lowScoreGuidance:
            'Incentivar a reflexão sobre a importância do autocuidado e da validação das emoções, evitando a minimização de sentimentos.',
        highScoreGuidance:
            'Abordar esquemas de desconexão e rejeição. Trabalhar na autoaceitação e autoafirmação, além de promover a identificação de padrões negativos.',
      ),
      PersonalityReferenceFacet(
        name: 'Embaraço/constrangimento',
        description:
            'Semelhante à timidez e ansiedade social, inclui emoções ligadas à vergonha e ao constrangimento.',
        lowScoreGuidance:
            'Enfatizar a construção de empatia e compreensão dos sentimentos alheios, promovendo um maior engajamento social.',
        highScoreGuidance:
            'Explorar esquemas de vergonha e desempenho. Implementar exercícios que promovam a exposição gradual a situações sociais.',
      ),
      PersonalityReferenceFacet(
        name: 'Impulsividade',
        description:
            'Diz respeito à dificuldade em controlar desejos e impulsos.',
        lowScoreGuidance:
            'Explorar como essa inibição pode ser limitante, incentivando a experimentação de novas experiências quando apropriado.',
        highScoreGuidance:
            'Trabalhar com esquemas de imediata gratificação. Desenvolver estratégias de autocontrole e atraso de gratificação.',
      ),
      PersonalityReferenceFacet(
        name: 'Vulnerabilidade',
        description:
            'Relativa à suscetibilidade ao estresse e a agressões psicológicas.',
        lowScoreGuidance:
            'Fomentar a consciência sobre os próprios limites e a importância de buscar ajuda quando necessário.',
        highScoreGuidance:
            'Identificar esquemas de vulnerabilidade. Trabalhar a construção de uma rede de suporte social que possa servir de apoio em momentos de estresse.',
      ),
    ],
  ),
  PersonalityReferenceFactor(
    name: 'Extroversão X Introversão',
    description:
        'Refere-se à intensidade das interações interpessoais e da busca e estimulação do meio.',
    facets: [
      PersonalityReferenceFacet(
        name: 'Acolhimento',
        description: 'Está associado a sentimentos de afeto e amizade.',
        lowScoreGuidance:
            'Trabalhar para aumentar a autoconfiança em ambientes sociais, incentivando pequenas interações.',
        highScoreGuidance:
            'Explorar esquemas de dependência. Promover a autoafirmação e a capacidade de estabelecer limites nos relacionamentos.',
      ),
      PersonalityReferenceFacet(
        name: 'Gregarismo',
        description:
            'Refere-se à preferência por interações sociais e convivência com outras pessoas.',
        lowScoreGuidance:
            'Promover a exploração de grupos sociais e novas atividades para aumentar a rede de suporte.',
        highScoreGuidance:
            'Abordar esquemas de aprovações. Incentivar o equilíbrio entre socialização e a necessidade de tempo para si.',
      ),
      PersonalityReferenceFacet(
        name: 'Assertividade',
        description:
            'Relaciona-se à capacidade de ser dominante, líder e independente.',
        lowScoreGuidance:
            'Incentivar a prática da assertividade em contextos seguros, ajudando a desenvolver a capacidade de se expressar.',
        highScoreGuidance:
            'Focar no equilíbrio entre liderança e empatia, evitando a dominação. Trabalhar em esquemas de superioridade se presentes.',
      ),
      PersonalityReferenceFacet(
        name: 'Atividade',
        description:
            'Representa a energia, agilidade e necessidade de movimento.',
        lowScoreGuidance:
            'Focar em incentivar pequenas mudanças na rotina que promovam mais movimento e atividade.',
        highScoreGuidance:
            'Explorar a busca excessiva por estímulos e a possível sobrecarga. Trabalhar na regulação da energia e no uso construtivo do tempo.',
      ),
      PersonalityReferenceFacet(
        name: 'Busca de sensações',
        description: 'Caracteriza a busca por novas experiências e estímulos.',
        lowScoreGuidance:
            'Incentivar a experimentação de novas atividades para expandir horizontes e combater a monotonia.',
        highScoreGuidance:
            'Trabalhar os limites da implementação de novas experiências e administrar riscos. Explorar esquemas de evitação e impulsividade.',
      ),
      PersonalityReferenceFacet(
        name: 'Emoções positivas',
        description:
            'Faceta mais importante para predição de felicidade. Aponta para a tendência de experimentar emoções construtivas, como alegria e amor.',
        lowScoreGuidance:
            'Trabalhar na identificação de pensamentos negativos que impedem o acesso a emoções positivas, promovendo a reinterpretação.',
        highScoreGuidance:
            'Fomentar a expressão de emoções positivas e explorar esquemas de autoimagem. Incentivar a prática de gratidão.',
      ),
    ],
  ),
  PersonalityReferenceFactor(
    name: 'Abertura à experiência X convencionalidade',
    description:
        'Indica o interesse por novas experiências ou preferências em manter uma postura mais conservadora.',
    facets: [
      PersonalityReferenceFacet(
        name: 'Fantasia',
        description:
            'Está ligada a uma imaginação vivída e uma vida fantasiosa ativa.',
        lowScoreGuidance:
            'Estimular a criatividade e a imaginação, propondo exercícios de visualização e brainstorming.',
        highScoreGuidance:
            'Integrar fantasias construtivas na vida cotidiana, evitando a desconexão da realidade.',
      ),
      PersonalityReferenceFacet(
        name: 'Estética',
        description:
            'Refere-se à apreciação por diversas formas de arte e beleza.',
        lowScoreGuidance:
            'Incentivar a exposição a diferentes formas de arte, ajudando a expandir a apreciação estética.',
        highScoreGuidance:
            'Explorar a ligação entre arte e emoções, promovendo a integração de experiências artísticas na vida.',
      ),
      PersonalityReferenceFacet(
        name: 'Sentimentos',
        description:
            'Trata da receptividade em relação às próprias emoções e sentimentos, reconhecendo sua importância na vida.',
        lowScoreGuidance:
            'Promover a consciência e validação dos próprios sentimentos, incentivando a autoexploração.',
        highScoreGuidance:
            'Trabalhar na identificação da sobrecarga emocional e na necessidade de regular essas emoções.',
      ),
      PersonalityReferenceFacet(
        name: 'Ações variadas',
        description:
            'Envolve a disposição para experimentar novas atividades e evitar a rotina.',
        lowScoreGuidance:
            'Incentivar a busca por novas experiências para combater a rigidez e fortalecer a adaptabilidade.',
        highScoreGuidance:
            'Trabalhar na percepção de que a variedade deve ser balanceada para evitar o estresse.',
      ),
      PersonalityReferenceFacet(
        name: 'Ideias',
        description:
            'Refere-se à curiosidade intelectual e abertura para novas propostas.',
        lowScoreGuidance:
            'Promover a curiosidade intelectual através da discussão e da abertura a novos conceitos.',
        highScoreGuidance:
            'Trabalhar na aposta de novas ideias, evitando a dispersão excessiva. Integrar pensamentos críticos para foco.',
      ),
      PersonalityReferenceFacet(
        name: 'Valores',
        description:
            'Diz respeito à disposição para reexaminar valores pessoais e sociais.',
        lowScoreGuidance:
            'Estimular a revisão de valores e crenças, promovendo a flexibilidade nas interpretações.',
        highScoreGuidance:
            'Fomentar reflexões sobre valores pessoais, assegurando que eles estejam alinhados com ações.',
      ),
    ],
  ),
  PersonalityReferenceFactor(
    name: 'Amabilidade X Antagonismo',
    description:
        'Relaciona-se à qualidade de orientação interpessoal; predisposição a se sensibilizar e ajudar as pessoas ou ter uma postura mais autocentrada.',
    facets: [
      PersonalityReferenceFacet(
        name: 'Confiança',
        description:
            'Está ligada à disposição de acreditar na honestidade dos outros.',
        lowScoreGuidance:
            'Incentivar a construção de um olhar mais positivo em relação aos outros, promovendo a empatia.',
        highScoreGuidance:
            'Trabalhar as relações de confiança, evitando a ingenuidade e a idealização excessiva das pessoas.',
      ),
      PersonalityReferenceFacet(
        name: 'Franqueza',
        description:
            'Relaciona-se à própria sinceridade e à lealdade para com a verdade.',
        lowScoreGuidance:
            'Focar na valorização da autenticidade e na prática de uma comunicação honesta.',
        highScoreGuidance:
            'Explorar os limites da franqueza e a importância da diplomacia em situações sociais.',
      ),
      PersonalityReferenceFacet(
        name: 'Altruísmo',
        description:
            'Refere-se à preocupação ativa com o bem-estar dos outros e disposição para assistir àqueles que precisam de ajuda.',
        lowScoreGuidance:
            'Encorajar pequenas ações de altruísmo e gentileza, para desenvolver a empatia.',
        highScoreGuidance:
            'Trabalhar no equilíbrio entre altruísmo e autoconservação, evitando a sobrecarga emocional.',
      ),
      PersonalityReferenceFacet(
        name: 'Complacência',
        description:
            'Diz respeito às reações aos conflitos interpessoais. Tendência a deferir em favor dos outros, a fim de evitar situações disruptivas.',
        lowScoreGuidance:
            'Incentivar a reflexão sobre a importância de manter relações saudáveis, defendendo suas opiniões e limites.',
        highScoreGuidance:
            'Trabalhar a assertividade e a necessidade de expressar opiniões, evitando a submissão excessiva.',
      ),
      PersonalityReferenceFacet(
        name: 'Modéstia',
        description: 'Relacionada à humildade, simplicidade e menor vaidade.',
        lowScoreGuidance:
            'Trabalhar a humildade e evitar o egocentrismo, promovendo um equilíbrio saudável na autopercepção.',
        highScoreGuidance:
            'Abordar o desenvolvimento da autoestima e a importância de reconhecer conquistas sem exagero.',
      ),
      PersonalityReferenceFacet(
        name: 'Sensibilidade',
        description:
            'Caracteriza atitudes de simpatia, compaixão e preocupação pelo bem-estar alheio.',
        lowScoreGuidance:
            'Estimular a empatia e a compreensão do ponto de vista dos outros, desenvolvendo relações interpessoais mais ricas.',
        highScoreGuidance:
            'Identificar padrões de autossabotagem e promover o autocuidado com a sensibilidade à dor alheia.',
      ),
    ],
  ),
  PersonalityReferenceFactor(
    name: 'Conscienciosidade X Desinibição',
    description:
        'Refere-se ao grau de persistência, força de vontade e determinação na orientação por um objetivo.',
    facets: [
      PersonalityReferenceFacet(
        name: 'Competência',
        description:
            'Refere-se à percepção da pessoa de que é capaz, sensível, prudente e efetiva. Associada com autoestima e controle interno.',
        lowScoreGuidance:
            'Encorajar a construção de um senso de competência através de pequenas conquistas.',
        highScoreGuidance:
            'Trabalhar a percepção de perfeccionismo e a pressão interna, promovendo uma visão realista das próprias capacidades.',
      ),
      PersonalityReferenceFacet(
        name: 'Ordem',
        description:
            'Diz respeito à organização, método, planejamento e preparação.',
        lowScoreGuidance:
            'Incentivar a prática de organização e planejamento, ajudando na criação de rotinas estruturadas.',
        highScoreGuidance:
            'Promover a flexibilidade em situações que exigem adaptação e improvisação, evitando a rigidez.',
      ),
      PersonalityReferenceFacet(
        name: 'Senso de dever',
        description: 'Envolve a responsabilidade social, moral e ética.',
        lowScoreGuidance:
            'Incentivar a reflexão sobre responsabilidades e valores pessoais, promovendo um senso de incumbência equilibrado.',
        highScoreGuidance:
            'Explorar a necessidade de atender expectativas externas e promover a definição de obrigações pessoais saudáveis.',
      ),
      PersonalityReferenceFacet(
        name: 'Esforço por realizações',
        description:
            'Refere-se à tendência de aspirar altos padrões e atitudes para alcançar metas.',
        lowScoreGuidance:
            'Incentivar o estabelecimento de metas claras e possíveis, promovendo a motivação.',
        highScoreGuidance:
            'Trabalhar na redefinição de metas realistas e incentivando o equilíbrio entre ambição e bem-estar.',
      ),
      PersonalityReferenceFacet(
        name: 'Autodisciplina',
        description:
            'Representa a habilidade de começar e concluir tarefas, mesmo diante de distrações.',
        lowScoreGuidance:
            'Focar na construção da autodisciplina através de rotinas e ações consistentes, estabelecendo prazos e recompensas.',
        highScoreGuidance:
            'Trabalhar a redução de rigidez e promover a aceitação do erro como parte do processo de aprendizagem.',
      ),
      PersonalityReferenceFacet(
        name: 'Ponderação',
        description: 'Diz respeito à tendência de refletir antes de agir.',
        lowScoreGuidance:
            'Promover a reflexão e a análise dos impactos das decisões, ajudando na construção de estratégias decisórias.',
        highScoreGuidance:
            'Incentivar a confiança nas decisões, reconhecendo quando refletir pode ser contraproducente.',
      ),
    ],
  ),
];
