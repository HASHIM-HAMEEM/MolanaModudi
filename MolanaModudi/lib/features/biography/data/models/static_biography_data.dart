import 'package:flutter/material.dart';
import '../../domain/entities/biography_event_entity.dart';

class StaticBiographyData {
  static const String name = "Sayyid Abul A'la Maududi";
  static const String title = "Islamic Scholar, Theologian & Political Thinker";
  static const String imageUrl = "assets/images/maulana_maududi.jpg";
  static const String quote = "Revival of Islam is not possible without a revival of Iman in the hearts of Muslims.";
  
  static const List<Map<String, dynamic>> quickFacts = [
    {
      'label': "Full Name",
      'value': "Sayyid Abul A'la Maududi",
      'icon': Icons.person,
      'location': "ابو الاعلیٰ المودودی (Urdu)"
    },
    {
      'label': "Born",
      'value': "September 25, 1903 (3 Rajab 1321 AH)",
      'icon': Icons.calendar_today,
      'location': "Aurangabad, Hyderabad State, British India"
    },
    {
      'label': "Died", 
      'value': "September 22, 1979 (aged 75)",
      'icon': Icons.calendar_today,
      'location': "Buffalo, New York, United States"
    },
    {
      'label': "Ancestry",
      'value': "Descendant of Prophet Muhammad",
      'icon': Icons.family_restroom,
      'location': "Through Chishti Sufi lineage"
    },
    {
      'label': "Father",
      'value': "Sayyid Ahmad Hasan Maududi",
      'icon': Icons.person,
      'location': "Lawyer & Sufi practitioner"
    },
    {
      'label': "Education",
      'value': "Traditional Islamic & Modern Studies",
      'icon': Icons.school,
      'location': "Aligarh, Deoband influences"
    },
    {
      'label': "Languages Mastered",
      'value': "7 Languages",
      'icon': Icons.language,
      'location': "Urdu, Arabic, Persian, English, Hindi, German, Turkish"
    },
    {
      'label': "Organization Founded",
      'value': "Jamaat-e-Islami (August 26, 1941)",
      'icon': Icons.account_balance,
      'location': "Lahore, British India"
    },
    {
      'label': "Leadership Period",
      'value': "31 Years (1941-1972)",
      'icon': Icons.schedule,
      'location': "First Amir of Jamaat-e-Islami"
    },
    {
      'label': "Magnum Opus",
      'value': "Tafhim-ul-Quran (6 Volumes)",
      'icon': Icons.menu_book,
      'location': "30-year project (1942-1972)"
    },
    {
      'label': "Total Publications",
      'value': "120+ Books & Pamphlets",
      'icon': Icons.library_books,
      'location': "Translated into 40+ languages"
    },
    {
      'label': "International Recognition",
      'value': "King Faisal International Prize (1979)",
      'icon': Icons.emoji_events,
      'location': "Service to Islam category"
    },
    {
      'label': "Global Influence",
      'value': "50+ Countries",
      'icon': Icons.public,
      'location': "Islamic movements worldwide"
    },
    {
      'label': "Imprisonments",
      'value': "Multiple Times",
      'icon': Icons.gavel,
      'location': "1948, 1953 (death sentence), 1964, 1967"
    },
    {
      'label': "Marriage",
      'value': "Mahmudah Begum (1937)",
      'icon': Icons.favorite,
      'location': "Distant cousin, modern educated woman"
    },
    {
      'label': "Final Resting Place",
      'value': "Ichhra Cemetery, Lahore",
      'icon': Icons.location_on,
      'location': "Pakistan - Massive funeral procession"
    }
  ];

  static const List<Map<String, dynamic>> lifeSections = [
    {
      'title': "Family Background & Noble Lineage",
      'icon': Icons.family_restroom,
      'content': [
        "Born into a distinguished family tracing ancestry to Prophet Muhammad through the Chishti Sufi lineage. His name 'Maududi' derives from Khawajah Syed Qutb ul-Din Maudood Chishti (d. 527 AH), the founder of the Chishti Silsilah.",
        "Father Ahmad Hasan was a lawyer educated at Aligarh College but later embraced traditional Sufism under Mawlvi Muhyu'ddin Khan. This shift from modern to traditional religious life deeply influenced young Maududi's worldview.",
        "Maternal grandfather Mirza Qurban Ali Baig Khan Salik was a renowned poet and writer in Hyderabad court, close friend of Mirza Ghalib. This literary heritage instilled in Maududi a love for scholarship and eloquent expression.",
        "Family had served Mughal courts and later Hyderabad's Asifiyah dynasty. The decline of Muslim political power from this aristocratic height created a lasting impact on Maududi's consciousness and mission.",
        "Grew up hearing stories of Islamic glory and witnessing the visible decline of Muslim institutions, which sparked his lifelong quest to understand and reverse this civilizational decline."
      ]
    },
    {
      'title': "Childhood & Early Education (1903-1918)",
      'icon': Icons.child_care,
      'content': [
        "Received intensive home education under his father's supervision, who wanted him to become a traditional Islamic scholar (maulvi). Mastered Arabic, Persian, Urdu, and basic Islamic sciences at an exceptionally young age.",
        "At age 11, translated Qasim Amin's controversial work 'Al-Mir'ah al-jadidah' (The New Woman) from Arabic to Urdu, demonstrating extraordinary linguistic abilities and mature comprehension of complex ideas.",
        "Attended Madrasa Fawqaniyya Mashriqiyya in Aurangabad (founded by Shibli Nomani), where he first encountered modern subjects like mathematics, physics, and chemistry alongside traditional Islamic studies.",
        "Father's mystical turn in 1900 meant the family lived in religious seclusion for years, with financial hardship forcing Maududi to mature quickly and develop self-reliance and introspective nature.",
        "Early exposure to both traditional Islamic learning and modern scientific thought created the intellectual foundation for his later synthesis of Islamic principles with contemporary challenges."
      ]
    },
    {
      'title': "Intellectual Awakening & Journalism (1918-1928)",
      'icon': Icons.edit,
      'content': [
        "Father's death when Maududi was 16 forced him to abandon formal education and enter journalism to support his family. This premature entry into professional life accelerated his intellectual development.",
        "Became editor of 'Taj' newspaper at age 17 in Delhi, where he was exposed to the vibrant political and intellectual atmosphere of the independence movement, initially supporting Indian nationalism.",
        "Spent five intensive years (1919-1924) systematically studying Western philosophy, political science, and history. Read works of Hegel, Comte, Mill, Darwin, Marx, Rousseau, Voltaire, and others to understand the foundations of Western civilization.",
        "Edited influential Islamic publications: 'Muslim' (1921-1923), 'al-Jamiah' (1924-1928), establishing himself as a formidable voice in Islamic intellectual discourse and political commentary.",
        "During this period wrote biographical works on Gandhi and Pandit Malaviya, showing his initial sympathy for Indian nationalism before his gradual turn toward Islamic revivalism.",
        "Self-taught English and German, enabling him to engage directly with Western sources and develop his sophisticated critique of both Western materialism and traditional Muslim stagnation."
      ]
    },
    {
      'title': "The Khilafat Movement Impact (1919-1924)",
      'icon': Icons.flag,
      'content': [
        "Actively participated in the Khilafat movement supporting the Ottoman Caliph, working with leaders like Muhammad Ali and getting involved in mass political mobilization for the first time.",
        "The collapse of the Ottoman Caliphate in 1924 was a devastating blow that fundamentally changed his worldview. He saw this as a betrayal by Turkish nationalists and Arab allies of the British.",
        "Witnessed how Western-inspired nationalism (Turkish, Arab) led to the destruction of the last symbol of Islamic political unity, making him permanently suspicious of all forms of nationalism.",
        "This experience taught him that emotional religious movements without solid ideological foundations and proper organization inevitably fail, shaping his later methodical approach to Islamic revival.",
        "Concluded that Muslims needed a comprehensive Islamic ideology and disciplined organization rather than sentimental attachment to historical symbols."
      ]
    },
    {
      'title': "Religious Studies & Scholarly Formation (1921-1928)",
      'icon': Icons.school,
      'content': [
        "Despite being a working journalist, undertook intensive Islamic studies with prominent Deobandi scholars at Fatihpuri Mosque seminary in Delhi, earning ijazahs (certificates) in 1926.",
        "Studied under Mawlana Abdul Salam Niyazi, Mawlana Ishfaq al-Rahman Kandhlawi, and other eminent scholars, mastering hadith, fiqh, tafsir, logic, and Islamic philosophy.",
        "His studies included the complete Dars-e-Nizami curriculum plus extensive reading in Sufism and Islamic philosophy, particularly the works of Mulla Sadra which deeply influenced his thought.",
        "Unlike traditional seminary graduates, he refused to be bound by conventional interpretations, developing his independent approach to Islamic scholarship and jurisprudence.",
        "This unique combination of traditional Islamic learning with modern Western education gave him unprecedented authority to speak to both religious scholars and modern educated Muslims."
      ]
    },
    {
      'title': "Intellectual Transformation (1928-1932)",
      'icon': Icons.lightbulb,
      'content': [
        "Moved to Hyderabad in 1928, shifting focus from journalism to serious scholarship. Wrote histories of Islamic dynasties (Saljuqids, Fatimids) and translated portions of Ibn Khallikan's historical works.",
        "Witnessed the visible decline of the last major Muslim state in India (Hyderabad) where Hindu merchants dominated commerce while Muslims remained politically powerant but economically dependent.",
        "Working at Hyderabad's Translation Institute (Daru'l-Tarjumah) exposed him to systematic translation of Western philosophical works, deepening his understanding of European intellectual foundations.",
        "His translation work on Mulla Sadra's 'Al-Asfar al-Arba'ah' (3,500 pages) introduced him to sophisticated Islamic philosophical concepts that later influenced his political theology.",
        "Began developing his distinctive interpretation of Islam as a complete system (nizam) rather than just personal religion, laying groundwork for his later revolutionary ideology."
      ]
    },
    {
      'title': "Conversion to Islamic Revivalism (1932-1937)",
      'icon': Icons.psychology,
      'content': [
        "In 1932, underwent what he described as a spiritual and intellectual conversion, moving from 'traditional and hereditary religion' to conscious, reasoned faith based on Quranic study.",
        "Bought and became editor of 'Tarjuman al-Quran' magazine in September 1932, which became his primary platform for developing and disseminating Islamic revival ideas for 47 years.",
        "Wrote 'Risalah-e-Diniyat' (later published as 'Towards Understanding Islam') in just 15 days, outlining the basic framework of Islam as a comprehensive way of life.",
        "His 1937 encounter with Congress leader B.G. Kher convinced him that Hindu-majority democracy would inevitably lead to Muslim subjugation, finalizing his opposition to Indian nationalism.",
        "Developed his systematic critique of both Western democracy and traditional Muslim quietism, arguing for Islamic revolution through education and organization rather than violent upheaval."
      ]
    },
    {
      'title': "Founding & Leading Jamaat-e-Islami (1941-1972)",
      'icon': Icons.groups,
      'content': [
        "Founded Jamaat-e-Islami on August 26, 1941, in Lahore with 75 founding members, creating the first modern Islamic party with clear ideology, constitution, and systematic membership requirements.",
        "Initially opposed partition of India, believing it would divide the Muslim ummah, but after Pakistan's creation focused entirely on transforming it into a true Islamic state.",
        "Developed unique organizational structure with rigorous membership criteria, systematic training programs, regular elections, and emphasis on character building alongside intellectual development.",
        "Led the organization for 31 years through multiple crises, government repression, and internal challenges while maintaining its ideological purity and organizational discipline.",
        "Created a cadre-based movement that prioritized quality over quantity, producing highly committed activists who carried Islamic revival ideas across the Muslim world.",
        "Established women's wing, student organizations, and professional groups, creating a comprehensive movement addressing all sectors of society with Islamic perspective."
      ]
    },
    {
      'title': "Political Struggles & Imprisonments (1947-1972)",
      'icon': Icons.gavel,
      'content': [
        "First imprisonment (1948): Criticized Pakistan government's Kashmir policy and secret support for insurgency while publicly claiming neutrality. Spent months in prison with other JI leaders.",
        "Anti-Ahmadiyya movement (1953): Led campaign to declare Ahmadiyyas non-Muslims and remove them from government positions. Sentenced to death but released due to massive public pressure.",
        "His dignified response to death sentence (refusing to appeal for mercy) greatly enhanced his moral authority and established him as a principled leader willing to die for his beliefs.",
        "Multiple imprisonments under Ayub Khan (1964, 1967) for opposing his secular modernization program and supporting traditional Islamic values against Western-oriented reforms.",
        "Despite political persecution, maintained organizational discipline and continued scholarly work, demonstrating the strength of his methodical approach to Islamic revival.",
        "Supported Fatima Jinnah against Ayub Khan (1965), showing pragmatic flexibility while maintaining core principles about Islamic governance and social justice."
      ]
    },
    {
      'title': "Literary & Scholarly Achievements",
      'icon': Icons.book,
      'content': [
        "Authored over 120 books and pamphlets covering Quranic commentary, Islamic law, political theory, economics, sociology, history, and contemporary issues.",
        "Completed 'Tafhim-ul-Quran' (1942-1972): Monumental 6-volume Quranic commentary taking 30 years, combining traditional exegesis with contemporary insights and practical guidance.",
        "'Al-Jihad fi'l-Islam' (1930): Groundbreaking exposition of jihad doctrine that clarified misconceptions and established proper Islamic framework for understanding holy war.",
        "'Khilafat aur Malukiyat' (1966): Critical analysis distinguishing between true Islamic caliphate and autocratic monarchy, providing historical perspective on Islamic governance.",
        "'Islamic Way of Life': Concise yet comprehensive guide to Islamic principles for modern living, becoming one of the most widely read Islamic books globally.",
        "'The Economic System of Islam': Foundational work on Islamic economics that laid groundwork for modern Islamic banking and finance systems worldwide.",
        "His works translated into over 40 languages, making him one of the most widely read Islamic scholars in history with influence spanning from Morocco to Malaysia."
      ]
    },
    {
      'title': "Economic & Social Philosophy",
      'icon': Icons.account_balance,
      'content': [
        "Developed comprehensive Islamic economic theory rejecting both capitalism and socialism, proposing Islam as the 'third way' balancing individual rights with social justice.",
        "His 1941 lecture 'The Economic Problem of Man and Its Islamic Solution' is considered a founding document of modern Islamic economics movement.",
        "Argued that poverty and exploitation result from lack of moral values rather than structural economic problems, emphasizing character transformation over systemic change.",
        "Advocated for prohibition of interest (riba) with death penalty for repeat offenders, proposing profit-and-loss sharing as alternative to interest-based finance.",
        "Opposed land reforms and socialist redistribution as violations of property rights, leading to criticism from leftist movements but maintaining consistency with Islamic law.",
        "His economic ideas influenced establishment of Islamic banks, insurance companies, and financial institutions across the Muslim world in subsequent decades."
      ]
    },
    {
      'title': "Global Impact & International Relations (1956-1979)",
      'icon': Icons.public,
      'content': [
        "Participated in 10 international Islamic conferences, spreading his ideas across the Muslim world and establishing connections with Islamic movements globally.",
        "Influenced founding and ideology of Muslim Brotherhood affiliates, Hizb-e-Islami movements, and Islamic parties from Turkey to Indonesia and Malaysia.",
        "His concept of 'Islamic State' became central to 20th-century Islamic political thought, inspiring movements seeking to establish Islamic governance worldwide.",
        "Collaborated in establishing Islamic University of Madinah, influencing Islamic education curricula and producing scholars who carried his ideas globally.",
        "Received King Faisal International Prize for Service to Islam (1979), recognizing his contribution as the most systematic thinker of modern Islamic revival.",
        "His methodology of gradual Islamic revolution through education and organization (rather than violence) became the preferred approach for mainstream Islamic movements.",
        "Influenced Iranian Revolution architects, Central Asian Islamic movements, North African Islamic parties, and Southeast Asian dakwah organizations."
      ]
    },
    {
      'title': "Personal Life & Character",
      'icon': Icons.person_pin,
      'content': [
        "Married Mahmudah Begum in 1937, an educated woman from a wealthy family who initially rode bicycles and didn't observe strict purdah but gradually adopted conservative practices.",
        "Known for his austere lifestyle, disciplined routine, and complete dedication to his mission despite offers of comfortable academic positions and government roles.",
        "His personal transformation from clean-shaven, Western-dressed young man to bearded traditional scholar reflected his gradual deepening commitment to Islamic practice.",
        "Maintained extensive correspondence with followers worldwide, providing personal guidance and organizational direction while continuing his scholarly work.",
        "Despite multiple imprisonments and death sentence, never compromised his principles or sought political accommodation at expense of ideological consistency.",
        "His dignified demeanor, intellectual honesty, and moral courage earned respect even from political opponents and established him as a role model for Islamic activists."
      ]
    },
    {
      'title': "Philosophy of Islamic Revolution",
      'icon': Icons.auto_awesome,
      'content': [
        "Coined and popularized the concept of 'Islamic Revolution' in the 1940s, emphasizing gradual transformation through education rather than violent overthrow.",
        "Argued that genuine Islamic change must begin with individual spiritual and moral transformation before attempting political and social reformation.",
        "Rejected both sudden revolutionary violence and traditional quietist approaches, advocating 'step-by-step' progress with patience and systematic planning.",
        "Emphasized that Islamic revolution requires creating a trained cadre of committed believers who understand both Islamic principles and contemporary challenges.",
        "His revolution aimed at establishing 'Divine Sovereignty' (Hakimiyyah) in all spheres of life: personal, social, economic, political, and international.",
        "Believed Islamic revolution must be global rather than limited to one country, aiming to establish Islamic order throughout the Muslim world and beyond."
      ]
    },
    {
      'title': "Legacy & Continuing Influence",
      'icon': Icons.stars,
      'content': [
        "His ideas continue to influence Islamic movements globally, from mainstream political parties to grassroots educational organizations and social reform movements.",
        "Modern Islamic banking and finance systems worldwide trace their theoretical foundations to his economic writings and practical proposals.",
        "Islamic universities and educational institutions across the Muslim world incorporate his methodology of combining traditional Islamic learning with contemporary knowledge.",
        "His interpretation of Islam as a complete system rather than personal religion became the dominant discourse in 20th-century Islamic revivalism.",
        "Jamaat-e-Islami organizations in Pakistan, India, Bangladesh, Kashmir, and other countries continue implementing his organizational model and ideological framework.",
        "His emphasis on intellectual development, character building, and gradual change influenced the peaceful nature of most contemporary Islamic movements.",
        "Even critics acknowledge his role in articulating the most sophisticated and systematic Islamic response to modernity and Western civilization."
      ]
    }
  ];

  static const List<Map<String, dynamic>> majorWorks = [
    {
      'title': "Tafhim-ul-Quran (The Meaning of the Quran)",
      'description': "Monumental 6-volume Quranic commentary and translation combining traditional exegesis with contemporary insights. His masterpiece that took 30 years to complete.",
      'year': "1942-1972",
      'significance': "Most comprehensive modern Quranic commentary in Urdu, making Quranic guidance accessible to educated Muslims worldwide. Translated into dozens of languages.",
      'pages': "5,000+ pages",
      'impact': "Primary source for Islamic movements globally"
    },
    {
      'title': "Al-Jihad fi'l-Islam (Jihad in Islam)",
      'description': "Systematic exposition of Islamic doctrine of jihad, clarifying misconceptions and establishing proper juridical framework for understanding holy war in Islam.",
      'year': "1930",
      'significance': "Groundbreaking work that defended Islam against accusations of violence while maintaining authenticity of jihad doctrine within proper legal constraints.",
      'pages': "300+ pages",
      'impact': "Standard reference for understanding jihad in Islamic law"
    },
    {
      'title': "Khilafat aur Malukiyat (Caliphate and Monarchy)",
      'description': "Critical historical analysis distinguishing between true Islamic caliphate and autocratic monarchy, examining the transformation of Islamic governance.",
      'year': "1966",
      'significance': "Provided historical perspective on Islamic political institutions and critiqued deviations from authentic Islamic governance principles.",
      'pages': "400+ pages",
      'impact': "Influenced understanding of Islamic political history"
    },
    {
      'title': "Risalah-e-Diniyat (Towards Understanding Islam)",
      'description': "Concise yet comprehensive introduction to Islamic beliefs, practices, and worldview written originally as textbook for students.",
      'year': "1932",
      'significance': "One of the most widely read Islamic books globally, translated into over 40 languages and used as standard introduction to Islam.",
      'pages': "150+ pages",
      'impact': "Primary da'wah tool for Islamic movements worldwide"
    },
    {
      'title': "Islami Tehzeeb aur uske Usul-o-Mabadi (Islamic Civilization and Its Principles)",
      'description': "Comprehensive analysis of Islamic civilization's foundations and principles compared to Western civilization.",
      'year': "1950",
      'significance': "Provided intellectual framework for understanding Islamic alternative to Western modernity and secularism.",
      'pages': "500+ pages",
      'impact': "Influenced Islamic intellectual discourse on civilization"
    },
    {
      'title': "Sud (Interest/Usury)",
      'description': "Detailed examination of Islamic prohibition of interest and its implications for modern economic systems.",
      'year': "1950",
      'significance': "Foundational text for Islamic banking and finance, providing theological and practical basis for interest-free economics.",
      'pages': "200+ pages",
      'impact': "Basis for global Islamic banking movement"
    },
    {
      'title': "Islami Riyasat (The Islamic State)",
      'description': "Comprehensive blueprint for establishing and running an Islamic state based on Quranic principles and Prophetic model.",
      'year': "1967",
      'significance': "Most systematic presentation of Islamic political theory and constitutional framework for modern times.",
      'pages': "800+ pages",
      'impact': "Standard reference for Islamic political movements"
    },
    {
      'title': "Tahrik-e-Azadi-e-Hind aur Musalman (Freedom Movement and Muslims)",
      'description': "Analysis of Muslim role in Indian independence movement and critique of nationalist ideology.",
      'year': "1939",
      'significance': "Articulated Islamic alternative to secular nationalism and provided ideological foundation for Pakistan movement.",
      'pages': "300+ pages",
      'impact': "Influenced Muslim political thought in subcontinent"
    },
    {
      'title': "Musalman aur Mawjudah Siyasi Kashmakash (Muslims and Current Political Struggle)",
      'description': "Series of articles analyzing contemporary political challenges facing Muslims and Islamic solutions.",
      'year': "1938-1940",
      'significance': "Provided Islamic perspective on major political issues and established Maududi as leading Muslim intellectual.",
      'pages': "400+ pages",
      'impact': "Shaped Islamic political discourse in 20th century"
    },
    {
      'title': "Dunya ki Maujudah Tehzeebon ka Jaiza (Survey of Contemporary Civilizations)",
      'description': "Comparative study of major world civilizations from Islamic perspective, examining their strengths and weaknesses.",
      'year': "1963",
      'significance': "Provided Islamic framework for understanding global civilizational challenges and Islam's role in modern world.",
      'pages': "350+ pages",
      'impact': "Influenced Islamic approach to international relations"
    }
  ];

  static List<BiographyEventEntity> getTimelineEvents() {
    return [
      const BiographyEventEntity(
        date: "September 25, 1903",
        title: "Birth in Aurangabad",
        description: "Born into noble family of Sayyid Ahmad Hasan in Aurangabad, Hyderabad State. Family traces ancestry to Prophet Muhammad through Chishti Sufi lineage."
      ),
      const BiographyEventEntity(
        date: "1907-1914",
        title: "Early Education & Father's Mystical Turn",
        description: "Father embraces Sufism, family moves to Delhi living in religious seclusion near Nizamuddin shrine. Maududi receives intensive Islamic education at home."
      ),
      const BiographyEventEntity(
        date: "1914",
        title: "Translation Achievement at Age 11",
        description: "Translates Qasim Amin's 'The New Woman' from Arabic to Urdu, demonstrating exceptional linguistic abilities and mature intellectual comprehension."
      ),
      const BiographyEventEntity(
        date: "1918",
        title: "First Publication",
        description: "Publishes article on electricity in 'Ma'arif' magazine at age 15, beginning his writing career with attempt to synthesize scientific knowledge with Islamic culture."
      ),
      const BiographyEventEntity(
        date: "1919-1920",
        title: "Father's Death & Entry into Journalism",
        description: "Father's death forces him to abandon formal education and support family. Becomes editor of 'Taj' newspaper at age 17 in Delhi."
      ),
      const BiographyEventEntity(
        date: "1919-1924",
        title: "Khilafat Movement Participation",
        description: "Actively supports Khilafat movement, works with Muslim leaders, and initially embraces Indian nationalism while studying Western philosophy intensively."
      ),
      const BiographyEventEntity(
        date: "1921-1926",
        title: "Islamic Studies with Deobandi Scholars",
        description: "Undertakes systematic Islamic education at Fatihpuri Mosque seminary while working as journalist. Receives ijazahs in traditional Islamic sciences."
      ),
      const BiographyEventEntity(
        date: "1924",
        title: "Collapse of Ottoman Caliphate",
        description: "Abolition of Caliphate by Turkish government devastates him, leading to permanent suspicion of nationalism and turn toward Islamic revivalism."
      ),
      const BiographyEventEntity(
        date: "1924-1928",
        title: "Editor of Al-Jamiah",
        description: "Edits influential Islamic journal 'al-Jamiah' for Jamiat Ulema-e-Hind, establishing himself as major voice in Islamic intellectual discourse."
      ),
      const BiographyEventEntity(
        date: "1928-1932",
        title: "Hyderabad Period & Scholarly Works",
        description: "Moves to Hyderabad, focuses on scholarship rather than journalism. Writes Islamic histories and works at Translation Institute on philosophical texts."
      ),
      const BiographyEventEntity(
        date: "1930",
        title: "Al-Jihad fi'l-Islam",
        description: "Completes groundbreaking work on jihad doctrine, earning praise from Muhammad Iqbal and establishing reputation as serious Islamic scholar."
      ),
      const BiographyEventEntity(
        date: "September 1932",
        title: "Buys Tarjuman al-Quran",
        description: "Acquires and becomes editor of 'Tarjuman al-Quran' magazine, which becomes his primary platform for developing Islamic revival ideas for 47 years."
      ),
      const BiographyEventEntity(
        date: "1932",
        title: "Spiritual & Intellectual Conversion",
        description: "Undergoes what he describes as conversion from 'traditional religion' to conscious Islamic faith. Writes 'Towards Understanding Islam' in 15 days."
      ),
      const BiographyEventEntity(
        date: "1937",
        title: "Marriage & Anti-Congress Turn",
        description: "Marries Mahmudah Begum. Encounter with Congress leader B.G. Kher convinces him of Hindu domination threat, finalizing opposition to Indian nationalism."
      ),
      const BiographyEventEntity(
        date: "1938-1940",
        title: "Move to Punjab & Dar-ul-Islam",
        description: "Moves to Pathankot, Punjab on Allama Iqbal's invitation to establish 'Dar-ul-Islam' as center for Islamic revival and training of committed Muslims."
      ),
      const BiographyEventEntity(
        date: "August 26, 1941",
        title: "Founding of Jamaat-e-Islami",
        description: "Establishes Jamaat-e-Islami in Lahore with 75 founding members, creating first modern Islamic party with systematic ideology and organization."
      ),
      const BiographyEventEntity(
        date: "1942",
        title: "Begins Tafhim-ul-Quran",
        description: "Starts his monumental Quranic commentary project that will take 30 years to complete and become his greatest scholarly achievement."
      ),
      const BiographyEventEntity(
        date: "1947",
        title: "Pakistan's Creation & Migration",
        description: "Despite initial opposition to partition, migrates to Pakistan and begins working to transform the new nation into a true Islamic state."
      ),
      const BiographyEventEntity(
        date: "1948",
        title: "First Imprisonment",
        description: "Imprisoned for criticizing government's Kashmir policy and secret support for insurgency while publicly claiming neutrality in Indo-Pak conflict."
      ),
      const BiographyEventEntity(
        date: "1953",
        title: "Anti-Ahmadiyya Movement & Death Sentence",
        description: "Leads campaign against Ahmadiyya community, sentenced to death by military court but released due to massive public pressure, enhancing his moral authority."
      ),
      const BiographyEventEntity(
        date: "1958-1969",
        title: "Ayub Khan Era Struggles",
        description: "Faces multiple imprisonments (1964, 1967) under Ayub Khan's secular modernization program while continuing organizational and scholarly work."
      ),
      const BiographyEventEntity(
        date: "1965",
        title: "Support for Fatima Jinnah",
        description: "Supports Fatima Jinnah against Ayub Khan in presidential election, showing pragmatic flexibility while maintaining Islamic principles."
      ),
      const BiographyEventEntity(
        date: "1970",
        title: "Electoral Disappointment",
        description: "Jamaat-e-Islami wins only 4 National Assembly seats despite massive campaign effort, leading to Maududi's temporary withdrawal from active politics."
      ),
      const BiographyEventEntity(
        date: "1972",
        title: "Completion of Tafhim & Resignation",
        description: "Completes 6-volume Tafhim-ul-Quran commentary and resigns as Amir of Jamaat-e-Islami due to health issues and organizational succession planning."
      ),
      const BiographyEventEntity(
        date: "1977",
        title: "Return to Political Center Stage",
        description: "Returns to active politics supporting movement against Bhutto's government and later backing General Zia's Islamization program."
      ),
      const BiographyEventEntity(
        date: "1979",
        title: "King Faisal Prize",
        description: "Receives King Faisal International Prize for Service to Islam, becoming first recipient of this prestigious award recognizing his global contributions."
      ),
      const BiographyEventEntity(
        date: "September 22, 1979",
        title: "Death in Buffalo & Massive Funeral",
        description: "Dies in Buffalo, New York from kidney disease. Body flown to Lahore where massive funeral procession attended by hundreds of thousands demonstrates his impact."
      )
    ];
  }

  static const Map<String, dynamic> statistics = {
    'booksWritten': 120,
    'languagesTranslated': 40,
    'yearsOfActivism': 60,
    'jammatMembers': 15000, // At time of death
    'countriesInfluenced': 50,
    'pagesWritten': 15000, // Estimated total pages
    'speechesDelivered': 1000,
    'yearsOfImprisonment': 4,
    'educationalInstitutions': 100, // Influenced by his ideas
    'politicalMovements': 25, // Directly influenced worldwide
  };

  static const List<String> inspiringQuotes = [
     "Revival of Islam is not possible without a revival of Iman in the hearts of Muslims.",
     "Islam is not a religion in the Western understanding of the word. It is a faith and a way of life, a religion and a social order, a doctrine and a code of conduct, a set of values and principles and a social movement to realize them in history.",
     "The ultimate goal of Islam is to establish the sovereignty of Allah on earth and organize human life on the basis of His guidance.",
     "A Muslim society cannot be Islamic unless it accepts the Sharia and decides to abide by it in entirety.",
     "The foremost duty of an Islamic movement is to bring about a revolution in the intellectual and moral spheres.",
     "Islam wants to address the heart of every human being. Its appeal is to all mankind. It wants to reach the heart of every human being.",
     "The more sudden a change, the more short-lived it is. Step-by-step progress is the way to lasting reform.",
     "You must never take the exaggerated view of your rights which the protagonists of class war present before you.",
     "Islam does not concern itself with the modes of production and circulation of wealth, but with the spirit behind the economic activity.",
     "Everything in the universe is 'Muslim' for it obeys Allah by submission to His laws.",
     "In reality I am a new Muslim (dar haqiqat mein ik naw-musalman hun) - having found my faith through study rather than inheritance.",
     "The crisis has come. I can foresee that the horrors ahead would wipe out the traumatic events of 1857. Muslims may face yet greater misery.",
     "If the time of my death has come, no one can keep me from it; and if it has not come, they cannot send me to the gallows even if they hang themselves upside down in trying to do so.",
     "An Islamic state is a Muslim state, but a Muslim state may not be an Islamic state unless the Constitution of the state is based on the Qur'an and Sunnah.",
     "Islam is first of all the name of knowledge and, after knowledge, the name of action. A Muslim is distinct from an unbeliever only by two things: one is knowledge, the other action upon it.",
     "There was a time when I was also a believer of traditional and hereditary religion. At last I paid attention to the Holy Book and the Prophet's Sunnah. I understood Islam and renewed my faith in it voluntarily.",
     "I do not have the prerogative to belong to the class of Ulema. I am a man of the middle cadre, who has imbibed something from both systems of education, the new and the old.",
     "Islam is a revolutionary ideology and a revolutionary practice which aims at destroying the social order of the world totally and rebuilding it from scratch.",
     "We believe in cash, not in credit, so why narrate to us the story of paradise.",
     "Every thought has its own vocabulary and each thought has to be expressed in the proper balance of words."
   ];

  // Additional comprehensive data sections
  static const List<Map<String, dynamic>> contemporaries = [
    {
      'name': 'Allama Iqbal',
      'relationship': 'Intellectual mentor and inspiration',
      'interaction': 'Invited Maududi to Punjab and supported his early work'
    },
    {
      'name': 'Muhammad Ali Jinnah',
      'relationship': 'Political leader he initially opposed but later respected',
      'interaction': 'Criticized two-nation theory but accepted Pakistan reality'
    },
    {
      'name': 'Abu\'l-Kalam Azad',
      'relationship': 'Early influence turned intellectual rival',
      'interaction': 'Inspired by his Al-Hilal but later opposed his nationalism'
    },
    {
      'name': 'Husain Ahmad Madani',
      'relationship': 'Major intellectual and political opponent',
      'interaction': 'Debated composite nationalism vs. Islamic identity'
    },
    {
      'name': 'Hassan al-Banna',
      'relationship': 'Contemporary revivalist in Egypt',
      'interaction': 'Parallel development of Islamic movement ideology'
    }
  ];

  static const List<Map<String, dynamic>> keyInfluences = [
    {
      'source': 'Quran and Hadith',
      'impact': 'Primary foundation for all his thinking and methodology'
    },
    {
      'source': 'Shah Waliullah Dehlawi',
      'impact': 'Concept of comprehensive Islam and political activism'
    },
    {
      'source': 'Ibn Taymiyyah',
      'impact': 'Political theology and critique of traditional scholars'
    },
    {
      'source': 'Mulla Sadra',
      'impact': 'Philosophical framework for Islamic renaissance'
    },
    {
      'source': 'Western Political Theory',
      'impact': 'Modern concepts adapted for Islamic political framework'
    }
  ];
} 