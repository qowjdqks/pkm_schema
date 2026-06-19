<?xml version="1.0" encoding="UTF-8"?>

<!--
Schematron Validation Rules for Pokémon Metadata Records

This file complements the XSD schema (pkm_schema.xsd) by enforcing
business rules that cannot be expressed in XML Schema alone.

Schematron uses XPath patterns to validate complex cross-field
constraints and conditional dependencies.

**CHANGED** Rules marked with **CHANGED** were added or revised to remove
logic conflicts between optional fields, controlled values, evolution
relationships, and battle-effectiveness metadata.
-->

<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    <sch:title>Pokémon Metadata Schematron Validation Rules</sch:title>

    <!-- Namespace declarations make the rule contexts clearer while local-name() remains available for imported Dublin Core elements. -->
    <sch:ns prefix="pkm" uri="http://example.org/pokemon"/>
    <sch:ns prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>

    <!-- ===================================================== -->
    <!-- Pattern 1: Evolution Stage & Method Consistency      -->
    <!-- ===================================================== -->

    <sch:pattern id="evolution-consistency">
        <sch:rule context="*[local-name()='pokemon']">

            <!-- Rule 1a: Standalone Pokémon must not carry evolution method metadata. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Standalone'])
                or
                (
                    not(*[local-name()='evolutionMethodType'])
                    and
                    not(*[local-name()='evolutionMethod'])
                )
            ">
                ERROR: Pokémon with evolutionStage="Standalone" must not have evolutionMethodType or evolutionMethod.
            </sch:assert>

            <!-- Rule 1b: Standalone Pokémon must not have evolvesFrom element. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Standalone'])
                or
                not(*[local-name()='evolvesFrom'])
            ">
                ERROR: Pokémon with evolutionStage="Standalone" must not have an evolvesFrom element.
            </sch:assert>

            <!-- Rule 1c: Standalone Pokémon must not have evolvesTo element. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Standalone'])
                or
                not(*[local-name()='evolvesTo'])
            ">
                ERROR: Pokémon with evolutionStage="Standalone" must not have any evolvesTo elements.
            </sch:assert>

            <!-- Rule 1d: Base Form must have evolvesTo and must not have evolvesFrom. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Base Form'])
                or
                (
                    *[local-name()='evolvesTo']
                    and
                    not(*[local-name()='evolvesFrom'])
                )
            ">
                ERROR: Pokémon with evolutionStage="Base Form" must have at least one evolvesTo and must not have evolvesFrom.
            </sch:assert>

            <!-- Rule 1e: Middle Evolution must have both evolvesFrom and evolvesTo. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Middle Evolution'])
                or
                (
                    *[local-name()='evolvesFrom']
                    and
                    *[local-name()='evolvesTo']
                )
            ">
                ERROR: Pokémon with evolutionStage="Middle Evolution" must have both evolvesFrom and evolvesTo.
            </sch:assert>

            <!-- Rule 1f: Final Evolution must have evolvesFrom and must not have evolvesTo. -->
            <sch:assert test="
                not(*[local-name()='evolutionStage' and text()='Final Evolution'])
                or
                (
                    *[local-name()='evolvesFrom']
                    and
                    not(*[local-name()='evolvesTo'])
                )
            ">
                ERROR: Pokémon with evolutionStage="Final Evolution" must have evolvesFrom and must not have evolvesTo.
            </sch:assert>

            <!-- Rule 1g: Non-standalone Pokémon must not use evolutionMethodType="None". -->
            <sch:assert test="
                *[local-name()='evolutionStage' and text()='Standalone']
                or
                not(*[local-name()='evolutionMethodType' and normalize-space(.)='None'])
            ">
                ERROR: Only standalone Pokémon may use evolutionMethodType="None"; non-standalone records must use a specific method or omit the element.
            </sch:assert>

            <!-- Rule 1h: When a specific evolutionMethod is supplied, evolutionMethodType must also be supplied and cannot be None. -->
            <sch:assert test="
                not(*[local-name()='evolutionMethod'])
                or
                *[local-name()='evolutionMethodType' and normalize-space(.)!='None']
            ">
                ERROR: evolutionMethod requires a matching non-None evolutionMethodType.
            </sch:assert>

            <!-- Rule 1i: A record must not point to itself as an evolution source or target. -->
            <sch:assert test="
                not(*[local-name()='evolvesFrom'] = *[local-name()='identifier'])
                and
                not(*[local-name()='evolvesTo'] = *[local-name()='identifier'])
            ">
                ERROR: evolvesFrom and evolvesTo must not reference the same identifier as the current Pokémon record.
            </sch:assert>

        </sch:rule>
    </sch:pattern>

    <!-- ===================================================== -->
    <!-- Pattern 2: Type Consistency                           -->
    <!-- ===================================================== -->

    <sch:pattern id="type-consistency">
        <sch:rule context="*[local-name()='pokemon']">

            <!-- Rule 2a: primaryType must be different from secondaryType when secondaryType is present and not "None". Missing secondaryType is valid. -->
            <sch:assert test="
                not(*[local-name()='secondaryType'])
                or
                *[local-name()='secondaryType' and normalize-space(.)='None']
                or
                normalize-space(*[local-name()='primaryType']) != normalize-space(*[local-name()='secondaryType'])
            ">
                ERROR: primaryType must differ from secondaryType when secondaryType is present and not "None".
            </sch:assert>

            <!-- Rule 2b: Prefer omitting secondaryType instead of writing "None". -->
            <sch:report test="*[local-name()='secondaryType' and normalize-space(.)='None']">
                WARNING: Omit secondaryType for single-type Pokémon instead of using secondaryType="None".
            </sch:report>

            <!-- Rule 2c: A type should not appear in both strongAgainst and weakAgainst. -->
            <sch:assert test="
                empty(*[local-name()='strongAgainst'][normalize-space(.) = (for $w in ../*[local-name()='weakAgainst'] return normalize-space($w))])
            ">
                ERROR: The same type must not appear in both strongAgainst and weakAgainst.
            </sch:assert>

            <!-- Rule 2d: strongAgainst values must not be duplicated. -->
            <sch:assert test="
                count(*[local-name()='strongAgainst']) = count(distinct-values(for $s in *[local-name()='strongAgainst'] return normalize-space($s)))
            ">
                ERROR: Duplicate strongAgainst values are not allowed.
            </sch:assert>

            <!-- Rule 2e: weakAgainst values must not be duplicated. -->
            <sch:assert test="
                count(*[local-name()='weakAgainst']) = count(distinct-values(for $w in *[local-name()='weakAgainst'] return normalize-space($w)))
            ">
                ERROR: Duplicate weakAgainst values are not allowed.
            </sch:assert>

        </sch:rule>
    </sch:pattern>

    <!-- ===================================================== -->
    <!-- Pattern 3: Legendary Status Validation               -->
    <!-- ===================================================== -->

    <sch:pattern id="legendary-validation">
        <sch:rule context="*[local-name()='pokemon']">

            <!-- Rule 3a: Legendary/Mythical Pokémon should typically be Standalone or Final Evolution. -->
            <sch:report test="
                (*[local-name()='legendaryStatus' and (normalize-space(.)='Legendary' or normalize-space(.)='Mythical')])
                and
                (*[local-name()='evolutionStage' and (normalize-space(.)='Base Form' or normalize-space(.)='Middle Evolution')])
            ">
                WARNING: Pokémon marked as Legendary or Mythical should typically be Standalone or Final Evolution.
            </sch:report>

        </sch:rule>
    </sch:pattern>

    <!-- ===================================================== -->
    <!-- Pattern 4: Identifier and Value Quality    -->
    <!-- ===================================================== -->

    <sch:pattern id="identifier-and-value-quality">
        <sch:rule context="*[local-name()='pokemon']">

            <!-- Rule 4a: dc:identifier must follow the same local record identifier pattern as evolution references. -->
            <sch:assert test="matches(normalize-space(*[local-name()='identifier']), '^[0-9]{3}(-[A-Z]{3})?$')">
                ERROR: dc:identifier must use a three-digit Pokédex number with an optional three-letter suffix, such as 025 or 037-ALO.
            </sch:assert>

            <!-- Rule 4b: Required Dublin Core title and identifier values must not be blank. -->
            <sch:assert test="normalize-space(*[local-name()='title']) != '' and normalize-space(*[local-name()='identifier']) != ''">
                ERROR: dc:title and dc:identifier must not be blank.
            </sch:assert>

            <!-- Rule 4c: evolution relationship values must not be duplicated. -->
            <sch:assert test="
                count(*[local-name()='evolvesTo']) = count(distinct-values(for $e in *[local-name()='evolvesTo'] return normalize-space($e)))
            ">
                ERROR: Duplicate evolvesTo values are not allowed.
            </sch:assert>

            <!-- Rule 4d: ability values must not be duplicated. -->
            <sch:assert test="
                count(*[local-name()='ability']) = count(distinct-values(for $a in *[local-name()='ability'] return normalize-space($a)))
            ">
                ERROR: Duplicate ability values are not allowed.
            </sch:assert>

            <!-- Rule 4e: regional forms should use a suffix in their identifier. -->
            <sch:report test="
                *[local-name()='regionalVariant' and normalize-space(.)!='None']
                and
                not(matches(normalize-space(*[local-name()='identifier']), '^[0-9]{3}-[A-Z]{3}$'))
            ">
                WARNING: Regional variant records should use an identifier suffix, such as 037-ALO, to distinguish them from the original form.
            </sch:report>

            <!-- Rule 4f: non-regional records should usually omit regionalVariant instead of using "None". -->
            <sch:report test="*[local-name()='regionalVariant' and normalize-space(.)='None']">
                WARNING: Omit regionalVariant for non-regional Pokémon instead of using regionalVariant="None".
            </sch:report>

        </sch:rule>
    </sch:pattern>

</sch:schema>