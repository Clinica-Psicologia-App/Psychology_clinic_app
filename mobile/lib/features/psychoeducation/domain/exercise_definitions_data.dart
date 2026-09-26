import 'exercise_definition.dart';

// ignore_for_file: lines_longer_than_80_chars

/// Hardcoded exercise definitions for Fase 2 modules (numbers 13–19).
/// Keyed by module number.
const Map<int, ExerciseDefinition> kExerciseDefinitions = {
  13: _lib01,
  14: _lib02,
  15: _lib03,
  16: _lib04,
  17: _lib05,
  18: _lib06,
  19: _lib07,
};

// ---------------------------------------------------------------------------
// Lib 01 (module 13) — Meu Primeiro Mapa de Transformação
// ---------------------------------------------------------------------------
const _lib01 = ExerciseDefinition(
  moduleNumber: 13,
  title: 'Meu Primeiro Mapa de Transformação',
  intro:
      'A mudança começa quando consigo observar meus padrões com mais clareza. '
      'Neste exercício, você vai explorar uma situação real da sua vida e '
      'identificar o que está pronto para mudar.',
  steps: [
    ExerciseStep(
      title: 'ETAPA 1 — Observando minha história',
      fields: [
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'Um padrão que percebo em mim:',
          hint: 'Descreva uma situação em que esse padrão apareceu...',
        ),
        ExerciseField(
          key: 's1_areas',
          type: ExerciseFieldType.multicheck,
          prompt: 'Em quais situações esse padrão aparece?',
          options: ['Relacionamentos', 'Família', 'Trabalho/Estudos', 'Amizades', 'Comigo mesmo(a)'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's1_emotions',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que normalmente sinto quando esse padrão aparece?',
          options: ['Medo', 'Tristeza', 'Raiva', 'Vergonha', 'Culpa', 'Ansiedade', 'Frustração'],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 2 — O que esse padrão faz por mim?',
      fields: [
        ExerciseField(
          key: 's2_behaviors',
          type: ExerciseFieldType.multicheck,
          prompt: 'Como costumo reagir quando esse padrão é ativado?',
          options: [
            'Evito a situação',
            'Fico em silêncio',
            'Tento agradar',
            'Fico na defensiva',
            'Me isolo',
            'Reajo com intensidade',
          ],
          allowOther: true,
        ),
        ExerciseField(
          key: 's2_protection',
          type: ExerciseFieldType.text,
          prompt: 'Esse padrão pode estar me protegendo de:',
          hint: 'O que ele tenta evitar?',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 3 — Compreendendo o impacto',
      fields: [
        ExerciseField(
          key: 's3_impact_life',
          type: ExerciseFieldType.text,
          prompt: 'Como esse padrão afetou minha vida até hoje?',
          hint: 'Pense em relacionamentos, trabalho, autoestima...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 4 — Escolhendo um novo caminho',
      fields: [
        ExerciseField(
          key: 's4_new_response',
          type: ExerciseFieldType.text,
          prompt: 'Uma resposta mais saudável que gostaria de experimentar:',
          hint: 'O que seu Adulto Saudável faria diferente?',
        ),
        ExerciseField(
          key: 's4_next_step',
          type: ExerciseFieldType.text,
          prompt: 'Um pequeno passo que posso dar esta semana:',
          hint: 'Algo concreto e possível...',
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 02 (module 14) — Meu Caminho para a Mudança
// ---------------------------------------------------------------------------
const _lib02 = ExerciseDefinition(
  moduleNumber: 14,
  title: 'Meu Caminho para a Mudança',
  intro:
      'A mudança acontece em pequenos passos. Neste exercício, você vai observar '
      'uma situação real e perceber como sua resposta pode evoluir com o tempo.',
  steps: [
    ExerciseStep(
      title: 'ETAPA 1 — Uma situação que trouxe aprendizado',
      fields: [
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'Descreva uma situação recente em que você percebeu uma mudança (mesmo pequena):',
          hint: 'O que aconteceu?',
        ),
        ExerciseField(
          key: 's1_before',
          type: ExerciseFieldType.text,
          prompt: 'Antes, eu costumava pensar/sentir/reagir:',
          hint: 'Como você teria respondido no passado?',
        ),
        ExerciseField(
          key: 's1_now',
          type: ExerciseFieldType.text,
          prompt: 'Hoje, percebo que:',
          hint: 'O que mudou ou começou a mudar?',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 2 — O que ainda me desafia',
      fields: [
        ExerciseField(
          key: 's2_challenge',
          type: ExerciseFieldType.text,
          prompt: 'Uma situação que ainda me desafia:',
          hint: 'Onde sinto que o caminho ainda está sendo construído?',
        ),
        ExerciseField(
          key: 's2_emotions',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que sinto nessa situação desafiadora?',
          options: ['Medo', 'Tristeza', 'Raiva', 'Vergonha', 'Ansiedade', 'Frustração', 'Esperança'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's2_behaviors',
          type: ExerciseFieldType.multicheck,
          prompt: 'Como costumo reagir nessa situação?',
          options: [
            'Evito',
            'Me calo',
            'Fico na defensiva',
            'Tento agradar',
            'Me cobro muito',
            'Busco apoio',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 3 — O que preciso',
      fields: [
        ExerciseField(
          key: 's3_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que uma parte minha precisa nessa situação?',
          options: [
            'Segurança',
            'Conexão',
            'Reconhecimento',
            'Autonomia',
            'Expressão emocional',
            'Limites e respeito',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 4 — Meu próximo passo',
      fields: [
        ExerciseField(
          key: 's4_adult_response',
          type: ExerciseFieldType.text,
          prompt: 'O que meu Adulto Saudável gostaria de fazer nessa situação:',
          hint: 'Como ele cuidaria de você?',
        ),
        ExerciseField(
          key: 's4_action',
          type: ExerciseFieldType.text,
          prompt: 'Um passo concreto que posso tentar:',
          hint: 'Algo pequeno e possível...',
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 03 (module 15) — Meu Mapa de Modos
// ---------------------------------------------------------------------------
const _lib03 = ExerciseDefinition(
  moduleNumber: 15,
  title: 'Meu Mapa de Modos',
  intro:
      'Dentro de nós existem diferentes partes que aparecem em momentos distintos. '
      'A mudança começa quando consigo observar qual parte minha apareceu, '
      'o que ela tentou fazer por mim, e como meu Adulto Saudável pode responder.',
  steps: [
    ExerciseStep(
      title: 'ETAPA 1 — Identificando uma situação',
      fields: [
        ExerciseField(
          key: 's1_areas',
          type: ExerciseFieldType.multicheck,
          prompt: 'Isso pode ter acontecido em:',
          options: ['Relacionamento amoroso', 'Família', 'Trabalho/Estudos', 'Amigos', 'Comigo mesmo(a)'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'O que aconteceu?',
          hint: 'Descreva a situação...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 2 — Qual parte minha apareceu?',
      fields: [
        ExerciseField(
          key: 's2_mode',
          type: ExerciseFieldType.multicheck,
          prompt: 'Qual Modo pareceu assumir mais espaço?',
          options: [
            'Criança Vulnerável',
            'Criança Zangada',
            'Criança Impulsiva/Indisciplinada',
            'Pais Internalizados (crítico ou exigente)',
            'Parte que Evita Sentir',
            'Parte que Busca Aprovação ou Valor',
            'Parte que Busca Controle ou Perfeição',
            'Parte que se Submete ou Desiste',
            'Adulto Saudável',
          ],
        ),
        ExerciseField(
          key: 's2_perceived_through',
          type: ExerciseFieldType.multicheck,
          prompt: 'Percebi essa parte através de:',
          options: ['Pensamentos', 'Emoções', 'Sensações no corpo', 'Comportamentos', 'Vontades ou impulsos'],
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 3 — Compreendendo a intenção',
      fields: [
        ExerciseField(
          key: 's3_protection',
          type: ExerciseFieldType.text,
          prompt: 'Quando essa parte aparece, talvez ela esteja tentando me proteger de:',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's3_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que essa parte precisava naquele momento?',
          options: ['Segurança', 'Aceitação', 'Cuidado', 'Ser ouvido(a)', 'Ter limites', 'Expressar sentimentos', 'Ser valorizado(a)'],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 4 — Olhando com compreensão',
      fields: [
        ExerciseField(
          key: 's4_understanding',
          type: ExerciseFieldType.text,
          prompt: 'O que consigo compreender sobre essa parte hoje?',
          hint: 'Pergunte: "Que história fez essa parte aprender a responder dessa forma?"',
        ),
        ExerciseField(
          key: 's4_was_necessary',
          type: ExerciseFieldType.singlecheck,
          prompt: 'Essa forma de proteção já foi importante em algum momento da minha vida?',
          options: ['Sim', 'Talvez', 'Ainda não consigo perceber'],
        ),
        ExerciseField(
          key: 's4_when_necessary',
          type: ExerciseFieldType.text,
          prompt: 'Se sim, quando ela pode ter sido necessária?',
          hint: 'Opcional...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 5 — Permitindo uma nova resposta',
      fields: [
        ExerciseField(
          key: 's5_adult_words',
          type: ExerciseFieldType.text,
          prompt: 'O que seu Adulto Saudável diria para essa parte?',
          hint: 'Imagine essa conversa...',
        ),
        ExerciseField(
          key: 's5_new_behavior',
          type: ExerciseFieldType.multicheck,
          prompt: 'Um pequeno passo que posso praticar:',
          options: [
            'Expressar uma necessidade',
            'Pedir ajuda',
            'Colocar um limite',
            'Permitir sentir uma emoção difícil',
            'Ser menos crítico(a) comigo',
            'Fazer uma pausa antes de reagir',
            'Cuidar melhor de mim',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 6 — Fortalecendo meu Adulto Saudável',
      fields: [
        ExerciseField(
          key: 's6_recognition',
          type: ExerciseFieldType.text,
          prompt: 'Quando reconheço minhas partes internas com compreensão, eu consigo:',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's6_aligned_choice',
          type: ExerciseFieldType.text,
          prompt: 'Uma escolha mais alinhada com quem quero ser é:',
          hint: 'Complete a frase...',
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 04 (module 16) — Meu Mapa de Ciclos Esquemáticos
// ---------------------------------------------------------------------------
const _lib04 = ExerciseDefinition(
  moduleNumber: 16,
  title: 'Meu Mapa de Ciclos Esquemáticos',
  intro:
      'Este exercício ajuda você a observar uma situação importante da sua vida '
      'e compreender: o que aconteceu, o que foi ativado, qual necessidade estava '
      'presente, qual modo apareceu, como você pode responder de forma mais saudável.',
  steps: [
    ExerciseStep(
      title: 'Etapa 1 — Escolhendo uma situação',
      fields: [
        ExerciseField(
          key: 's1_trigger_type',
          type: ExerciseFieldType.multicheck,
          prompt: 'Você percebeu:',
          options: [
            'Uma emoção intensa',
            'Uma reação automática',
            'Dificuldade em lidar com alguém',
            'Um comportamento que depois gostaria de ter feito diferente',
          ],
        ),
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'O que aconteceu?',
          hint: 'Descreva a situação...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 2 — Identificando o gatilho',
      fields: [
        ExerciseField(
          key: 's2_trigger',
          type: ExerciseFieldType.text,
          prompt: 'O que pareceu ativar algo dentro de você?',
          hint: 'Algo que alguém disse, uma atitude, uma mudança inesperada...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 3 — Percebendo minha reação',
      fields: [
        ExerciseField(
          key: 's3_body',
          type: ExerciseFieldType.multicheck,
          prompt: 'No meu corpo eu percebi:',
          options: ['Tensão', 'Aceleração', 'Aperto', 'Vontade de fugir', 'Vontade de atacar'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's3_emotion',
          type: ExerciseFieldType.multicheck,
          prompt: 'Minha emoção principal foi:',
          options: ['Medo', 'Tristeza', 'Raiva', 'Vergonha', 'Culpa', 'Ansiedade'],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 4 — Compreendendo meus pensamentos',
      fields: [
        ExerciseField(
          key: 's4_thought1',
          type: ExerciseFieldType.text,
          prompt: 'O que passou pela minha mente?',
          prefix: 'Eu pensei que...',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's4_thought2',
          type: ExerciseFieldType.text,
          prompt: 'Como interpretei essa situação?',
          prefix: 'Eu interpretei essa situação como...',
          hint: 'Complete a frase...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 5 — Descobrindo minha necessidade',
      fields: [
        ExerciseField(
          key: 's5_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'Minha necessidade pode ter sido:',
          options: [
            'Sentir segurança',
            'Sentir conexão',
            'Ser valorizado(a)',
            'Ser respeitado(a)',
            'Ter autonomia',
            'Ser compreendido(a)',
            'Expressar meus sentimentos',
            'Estabelecer limites',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 6 — Conhecendo o modo que apareceu',
      fields: [
        ExerciseField(
          key: 's6_mode',
          type: ExerciseFieldType.multicheck,
          prompt: 'Qual parte minha parece ter assumido o controle?',
          options: [
            'Criança Vulnerável',
            'Criança Zangada',
            'Criança Impulsiva',
            'Criança Feliz',
            'Pai/Mãe Crítico(a) ou Exigente internalizado(a)',
            'Protetor Desligado',
          ],
          allowOther: true,
        ),
        ExerciseField(
          key: 's6_mode_function',
          type: ExerciseFieldType.multicheck,
          prompt: 'Esse modo tentou:',
          options: [
            'Evitar uma dor',
            'Me proteger de uma ameaça',
            'Conseguir atenção ou cuidado',
            'Evitar rejeição',
            'Manter controle',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 7 — Convidando meu Adulto Saudável',
      fields: [
        ExerciseField(
          key: 's7_adult_reminder',
          type: ExerciseFieldType.text,
          prompt: 'O que meu Adulto Saudável gostaria de me lembrar?',
          hint: 'O que ele diria de forma compassiva?',
        ),
        ExerciseField(
          key: 's7_healthy_response',
          type: ExerciseFieldType.text,
          prompt: 'Que resposta mais saudável eu poderia experimentar?',
          hint: 'Uma opção diferente...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'Etapa 8 — Meu novo caminho',
      fields: [
        ExerciseField(
          key: 's8_before',
          type: ExerciseFieldType.text,
          prompt: 'Antes eu costumava responder:',
          hint: 'Como você costumava reagir?',
        ),
        ExerciseField(
          key: 's8_now',
          type: ExerciseFieldType.text,
          prompt: 'Agora eu posso tentar:',
          hint: 'Uma nova possibilidade...',
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 05 (module 17) — Meu Mapa Pessoal de Padrões
// ---------------------------------------------------------------------------
const _lib05 = ExerciseDefinition(
  moduleNumber: 17,
  title: 'Meu Mapa Pessoal de Padrões',
  intro:
      'Ao longo desta biblioteca, você aprendeu a observar seus padrões com mais '
      'compreensão. Agora, o convite é reunir essas descobertas e olhar para uma '
      'situação real da sua vida. O objetivo não é encontrar erros — é compreender '
      'seu caminho interno e criar espaço para novas escolhas.',
  steps: [
    ExerciseStep(
      title: '1. Situação que aconteceu',
      fields: [
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'Pense em um momento recente em que uma reação conhecida apareceu. O que aconteceu?',
          hint: 'Descreva a situação...',
        ),
      ],
    ),
    ExerciseStep(
      title: '2. O que foi ativado em mim?',
      fields: [
        ExerciseField(
          key: 's2_emotions',
          type: ExerciseFieldType.multicheck,
          prompt: 'Emoções que eu percebi:',
          options: ['Medo', 'Tristeza', 'Raiva', 'Vergonha', 'Ansiedade'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's2_body',
          type: ExerciseFieldType.text,
          prompt: 'Sensações no corpo:',
          hint: 'Aperto, tensão, aceleração...',
        ),
        ExerciseField(
          key: 's2_thoughts',
          type: ExerciseFieldType.text,
          prompt: 'Pensamentos que apareceram:',
          hint: 'O que passou pela sua mente?',
        ),
      ],
    ),
    ExerciseStep(
      title: '3. Qual necessidade minha estava envolvida?',
      fields: [
        ExerciseField(
          key: 's3_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que essa situação pareceu tocar em mim?',
          options: [
            'Segurança',
            'Conexão e vínculo',
            'Reconhecimento',
            'Autonomia',
            'Expressão emocional',
            'Limites e respeito',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: '4. Qual parte minha apareceu?',
      fields: [
        ExerciseField(
          key: 's4_part',
          type: ExerciseFieldType.multicheck,
          prompt: 'Qual parte assumiu o controle?',
          options: [
            'Uma parte vulnerável e sensível',
            'Uma parte que tenta evitar sentir',
            'Uma parte que busca agradar',
            'Uma parte que tenta controlar',
            'Uma parte que se cobra muito',
            'Uma parte que tenta se defender',
          ],
        ),
        ExerciseField(
          key: 's4_part_intent',
          type: ExerciseFieldType.text,
          prompt: 'Essa parte parecia estar tentando:',
          hint: 'O que ela queria fazer por você?',
        ),
      ],
    ),
    ExerciseStep(
      title: '5. O que esse padrão tentou fazer por mim?',
      fields: [
        ExerciseField(
          key: 's5_protection',
          type: ExerciseFieldType.text,
          prompt: 'Essa reação apareceu porque uma parte minha queria me proteger de:',
          hint: 'Complete a frase...',
        ),
      ],
    ),
    ExerciseStep(
      title: '6. Qual foi o impacto dessa resposta?',
      fields: [
        ExerciseField(
          key: 's6_helped',
          type: ExerciseFieldType.text,
          prompt: 'No momento, essa reação me ajudou a:',
          hint: 'O que ela fez de útil?',
        ),
        ExerciseField(
          key: 's6_hindered',
          type: ExerciseFieldType.text,
          prompt: 'Depois, ela trouxe dificuldades como:',
          hint: 'Que consequências ela teve?',
        ),
      ],
    ),
    ExerciseStep(
      title: '7. Como meu Adulto Saudável poderia responder?',
      fields: [
        ExerciseField(
          key: 's7_adult_words',
          type: ExerciseFieldType.text,
          prompt: 'Meu Adulto Saudável poderia dizer:',
          hint: 'O que ele diria com compaixão?',
        ),
        ExerciseField(
          key: 's7_new_choice',
          type: ExerciseFieldType.text,
          prompt: 'Uma escolha diferente que posso experimentar é:',
          hint: 'Uma nova possibilidade...',
        ),
        ExerciseField(
          key: 's7_small_step',
          type: ExerciseFieldType.text,
          prompt: 'Um pequeno passo que quero praticar:',
          hint: 'Algo concreto e possível...',
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 06 (module 18) — Meu Mapa dos Relacionamentos
// ---------------------------------------------------------------------------
const _lib06 = ExerciseDefinition(
  moduleNumber: 18,
  title: 'Meu Mapa dos Relacionamentos',
  intro:
      'Nossos relacionamentos revelam muitas partes da nossa história. Neste exercício, '
      'você vai observar uma relação importante e compreender: como você se conecta, '
      'o que busca, o que teme, quais padrões aparecem, e quais novas escolhas deseja construir.',
  steps: [
    ExerciseStep(
      title: '1. Escolhendo uma relação importante',
      fields: [
        ExerciseField(
          key: 's1_relation_type',
          type: ExerciseFieldType.multicheck,
          prompt: 'Tipo de relacionamento:',
          options: ['Amoroso', 'Familiar', 'Amizade', 'Profissional'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's1_who',
          type: ExerciseFieldType.text,
          prompt: 'Quem escolhi observar? (pode ser só o papel: "minha mãe", "meu parceiro")',
          hint: 'Não precisa identificar a pessoa pelo nome...',
        ),
      ],
    ),
    ExerciseStep(
      title: '2. Como essa relação funciona hoje?',
      fields: [
        ExerciseField(
          key: 's2_feelings',
          type: ExerciseFieldType.multicheck,
          prompt: 'Quando estou com essa pessoa, geralmente eu me sinto:',
          options: ['Seguro(a)', 'Acolhido(a)', 'Conectado(a)', 'Preocupado(a)', 'Inseguro(a)', 'Distante'],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: '3. O que eu busco nessa relação?',
      fields: [
        ExerciseField(
          key: 's3_want_receive',
          type: ExerciseFieldType.text,
          prompt: 'Eu gostaria de receber mais:',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's3_want_express',
          type: ExerciseFieldType.text,
          prompt: 'Eu gostaria de poder expressar mais:',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's3_want_build',
          type: ExerciseFieldType.text,
          prompt: 'Eu gostaria de construir mais:',
          hint: 'Complete a frase...',
        ),
      ],
    ),
    ExerciseStep(
      title: '4. O que costuma ativar meus padrões?',
      fields: [
        ExerciseField(
          key: 's4_trigger',
          type: ExerciseFieldType.text,
          prompt: 'Quando acontece algo específico com essa pessoa:',
          hint: 'Descreva a situação...',
        ),
        ExerciseField(
          key: 's4_auto_thought',
          type: ExerciseFieldType.text,
          prompt: 'Meu pensamento automático costuma ser:',
          hint: 'O que você pensa imediatamente?',
        ),
        ExerciseField(
          key: 's4_reaction',
          type: ExerciseFieldType.multicheck,
          prompt: 'Minha reação mais comum é:',
          options: [
            'Buscar aproximação',
            'Me afastar',
            'Ficar em silêncio',
            'Tentar agradar',
            'Tentar controlar',
            'Entrar em conflito',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: '5. Qual necessidade minha está envolvida?',
      fields: [
        ExerciseField(
          key: 's5_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'O que uma parte minha está precisando?',
          options: [
            'Segurança',
            'Conexão',
            'Reconhecimento',
            'Respeito',
            'Autonomia',
            'Apoio',
            'Espaço para expressar sentimentos',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: '6. O que meu padrão tenta fazer por mim?',
      fields: [
        ExerciseField(
          key: 's6_protection',
          type: ExerciseFieldType.text,
          prompt: 'Uma parte minha reage assim porque tenta me proteger de:',
          hint: 'Complete a frase...',
        ),
        ExerciseField(
          key: 's6_was_important',
          type: ExerciseFieldType.text,
          prompt: 'Essa estratégia foi importante em algum momento porque:',
          hint: 'Quando ela fez sentido?',
        ),
      ],
    ),
    ExerciseStep(
      title: '7. Convidando meu Adulto Saudável',
      fields: [
        ExerciseField(
          key: 's7_adult_words',
          type: ExerciseFieldType.text,
          prompt: 'Meu Adulto Saudável poderia dizer:',
          hint: '"Eu entendo que você está tentando me proteger, mas hoje eu posso..."',
        ),
        ExerciseField(
          key: 's7_new_action',
          type: ExerciseFieldType.text,
          prompt: 'Uma nova forma de agir que quero experimentar:',
          hint: 'Uma opção diferente...',
        ),
        ExerciseField(
          key: 's7_small_step',
          type: ExerciseFieldType.multicheck,
          prompt: 'Meu pequeno passo de mudança:',
          options: [
            'Expressar algo que normalmente guardo',
            'Ouvir antes de responder',
            'Pedir algo que preciso',
            'Estabelecer um limite',
            'Demonstrar afeto',
            'Aceitar receber cuidado',
          ],
          allowOther: true,
        ),
      ],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lib 07 (module 19) — Escutando e cuidando das minhas necessidades emocionais
// ---------------------------------------------------------------------------
const _lib07 = ExerciseDefinition(
  moduleNumber: 19,
  title: 'Escutando e cuidando das minhas necessidades emocionais',
  intro:
      'Este exercício convida você a observar um momento em que algo importante '
      'dentro de você foi ativado. Ao reconhecer suas emoções, necessidades e formas '
      'de responder, você poderá construir novas maneiras de cuidar de si com o '
      'apoio do seu Adulto Saudável.',
  steps: [
    ExerciseStep(
      title: 'ETAPA 1 — Reconhecendo um momento de ativação',
      fields: [
        ExerciseField(
          key: 's1_situation',
          type: ExerciseFieldType.text,
          prompt: 'Pense em uma situação recente em que você sentiu desconforto emocional. O que aconteceu?',
          hint: 'Descreva a situação...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 2 — O que estava acontecendo dentro de mim?',
      fields: [
        ExerciseField(
          key: 's2_emotions',
          type: ExerciseFieldType.multicheck,
          prompt: 'Qual emoção apareceu?',
          options: ['Tristeza', 'Medo', 'Raiva', 'Vergonha', 'Culpa', 'Ansiedade', 'Solidão', 'Frustração'],
          allowOther: true,
        ),
        ExerciseField(
          key: 's2_body',
          type: ExerciseFieldType.text,
          prompt: 'Meu corpo sinalizou:',
          hint: 'Aperto no peito, tensão muscular, nó na garganta, agitação...',
        ),
        ExerciseField(
          key: 's2_thoughts',
          type: ExerciseFieldType.text,
          prompt: 'Meus pensamentos foram:',
          hint: '"Não sou importante." / "Vou ser rejeitado(a)." / ...',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 3 — Qual necessidade emocional estava presente?',
      fields: [
        ExerciseField(
          key: 's3_needs',
          type: ExerciseFieldType.multicheck,
          prompt: 'Quando vivi essa situação, do que eu precisava?',
          options: [
            'Conexão e pertencimento',
            'Segurança e proteção',
            'Autonomia e competência',
            'Expressão emocional',
            'Espontaneidade e lazer',
            'Limites e respeito',
            'Ser compreendido(a)',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 4 — Como costumo responder?',
      fields: [
        ExerciseField(
          key: 's4_coping',
          type: ExerciseFieldType.multicheck,
          prompt: 'Quando essa necessidade não é atendida, o que eu costumo fazer?',
          options: [
            'Evito sentir',
            'Me distraio para não pensar',
            'Me afasto das pessoas',
            'Tento agradar para evitar problemas',
            'Aceito situações que me machucam',
            'Coloco as necessidades dos outros acima das minhas',
            'Tento controlar tudo',
            'Me cobro excessivamente',
            'Tento provar meu valor',
          ],
          allowOther: true,
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 5 — Conversando com meu Adulto Saudável',
      fields: [
        ExerciseField(
          key: 's5_adult_words',
          type: ExerciseFieldType.text,
          prompt: 'Se meu Adulto Saudável pudesse cuidar dessa parte minha agora, o que ele diria?',
          hint: '"Eu entendo que você está sentindo..." / "Você não precisa enfrentar isso sozinho(a)..."',
        ),
      ],
    ),
    ExerciseStep(
      title: 'ETAPA 6 — Um pequeno passo diferente',
      fields: [
        ExerciseField(
          key: 's6_new_step',
          type: ExerciseFieldType.text,
          prompt: 'Qual pequena atitude diferente posso experimentar quando essa necessidade aparecer novamente?',
          hint: 'Pedir ajuda, expressar o que sinto, colocar um limite, descansar...',
        ),
      ],
    ),
  ],
);
