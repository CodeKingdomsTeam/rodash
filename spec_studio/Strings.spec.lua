return function()
	local Strings = require(script.Parent.Strings)
	describe(
		"Strings and UTF8",
		function()
			describe(
				"charToHex",
				function()
					it(
						"encodes correctly",
						function()
							assert.equal("3C", Strings.charToHex("<"))
						end
					)
					it(
						"encodes utf8 correctly",
						function()
							assert.equal("1F60F", Strings.charToHex("😏"))
						end
					)
					it(
						"encodes utf8 correctly with formatting",
						function()
							assert.equal("0x1F60F", Strings.charToHex("😏", "0x{}"))
						end
					)
					it(
						"encodes utf8 with multiple code points correctly",
						function()
							assert.equal("&#x1F937;&#x1F3FC;&#x200D;&#x2640;&#xFE0F;", Strings.charToHex("🤷🏼‍♀️", "&#x{};"))
						end
					)
					it(
						"encodes utf8 bytes correctly",
						function()
							assert.equal("%F0%9F%A4%B7%F0%9F%8F%BC%E2%80%8D%E2%99%80%EF%B8%8F", Strings.charToHex("🤷🏼‍♀️", "%{}", true))
						end
					)
				end
			)

			describe(
				"hexToChar",
				function()
					it(
						"decodes correctly",
						function()
							assert.equal("_", Strings.hexToChar("%5F"))
						end
					)
					it(
						"throws for an invalid encoding",
						function()
							assert.errors(
								function()
									Strings.hexToChar("nope")
								end
							)
						end
					)
				end
			)

			describe(
				"encodeUrlComponent",
				function()
					it(
						"encodes correctly",
						function()
							assert.equal(
								"https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F",
								Strings.encodeUrlComponent("https://example.com/Egg+Fried Rice!?")
							)
						end
					)
				end
			)
			describe(
				"encodeUrl",
				function()
					it(
						"encodes correctly",
						function()
							assert.equal("https://example.com/Egg+Fried%20Rice!?", Strings.encodeUrl("https://example.com/Egg+Fried Rice!?"))
						end
					)
				end
			)
			describe(
				"decodeUrlComponent",
				function()
					it(
						"decodes correctly",
						function()
							assert.equal(
								"https://example.com/Egg+Fried Rice!?",
								Strings.decodeUrlComponent("https%3A%2F%2Fexample.com%2FEgg%2BFried%20Rice!%3F")
							)
						end
					)
				end
			)
			describe(
				"decodeUrl",
				function()
					it(
						"decodes correctly",
						function()
							assert.equal("https://example.com/Egg+Fried Rice!?", Strings.decodeUrl("https://example.com/Egg+Fried%20Rice!?"))
						end
					)
				end
			)
			describe(
				"makeQueryString",
				function()
					it(
						"makes query",
						function()
							assert.equal(
								"?biscuits=hobnobs&time=11&chocolatey=true",
								Strings.encodeQueryString(
									{
										time = 11,
										biscuits = "hobnobs",
										chocolatey = true
									}
								)
							)
						end
					)
				end
			)

			describe(
				"encodeHtml",
				function()
					it(
						"characters",
						function()
							assert.are.same(
								"Peas &lt; Bacon &gt; &quot;Fish&quot; &amp; &apos;Chips&apos;",
								Strings.encodeHtml([[Peas < Bacon > "Fish" & 'Chips']])
							)
						end
					)
				end
			)

			describe(
				"decodeHtml",
				function()
					it(
						"html entities",
						function()
							assert.are.same(
								[[<b>"Smashed"</b> 'Avocado' 😏]],
								Strings.decodeHtml("&lt;b&gt;&#34;Smashed&quot;&lt;/b&gt; &apos;Avocado&#39; &#x1F60F;")
							)
						end
					)
					it(
						"conflated ampersand",
						function()
							assert.are.same("Ampersand is &amp;", Strings.decodeHtml("Ampersand is &#38;amp;"))
						end
					)
				end
			)
		end
	)
end
