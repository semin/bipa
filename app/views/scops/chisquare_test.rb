<% content_for :main_title do %>
  <div class="title">
    <%= @scop.hierarchy %>: <%= @scop.description %>
  </div>
<% end %>

<div id="tab_menu_container">
  <ul id="tab_menu">
    <li><%= link_to "Hierarchy", hierarchy_scop_path(@scop) %></li>
    <li><%= link_to "Distributions", distributions_scop_path(@scop) %></li>
    <li><%= link_to "Propensites", propensities_scop_path(@scop) %></li>
    <li><%= link_to "Chi-square Test", chisquare_test_scop_path(@scop), :class=> "current" %></li>
    <li><%= link_to "Alignments", scop_alignments_path(@scop) %></li>
    <li><%= link_to "Interfaces", scop_interfaces_path(@scop) %></li>
  </ul>
</div>

<div id="below_tab_menu">

  <h4>1. Protein-DNA complexes</h4>

  <% if @scop.dna_interfaces(session[:redundancy], session[:resolution]).size > 0 %>
    <h4>a. Distribution of hydrogen bonds</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">DA</th>
        <th colspan="2">DC</th>
        <th colspan="2">DG</th>
        <th colspan="2">DT</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
            <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_hbond_between_#{aa}_and_dna", session[:redundancy], session[:resolution]) %></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_hbond_between_amino_acids_and_#{dna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_dna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_dna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_dna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />


    <h4>b. Distribution of water-mediated hydrogen bonds</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">DA</th>
        <th colspan="2">DC</th>
        <th colspan="2">DG</th>
        <th colspan="2">DT</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
            <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_whbond_between_#{aa}_and_dna", session[:redundancy], session[:resolution])%></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_whbond_between_amino_acids_and_#{dna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_dna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_dna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_dna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />


    <h4>c. Distribution of van der Waals contacts</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">DA</th>
        <th colspan="2">DC</th>
        <th colspan="2">DG</th>
        <th colspan="2">DT</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
            <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_#{dna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_dna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_dna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_contact_between_#{aa}_and_dna", session[:redundancy], session[:resolution])%></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_contact_between_amino_acids_and_#{dna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_dna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_dna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_dna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />
  <% else %>
    N/A
  <% end %>


  <h4>2. Protein-RNA complexes</h4>

  <% if @scop.rna_interfaces(session[:redundancy], session[:resolution]).size > 0 %>

    <h4>a. Distribution of hydrogen bonds</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">A</th>
        <th colspan="2">C</th>
        <th colspan="2">G</th>
        <th colspan="2">T</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
            <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_hbond_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_hbond_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_hbond_between_#{aa}_and_rna", session[:redundancy], session[:resolution])%></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_hbond_between_amino_acids_and_#{rna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_rna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_rna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_hbond_between_amino_acids_and_rna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />


    <h4>b. Distribution of water-mediated hydrogen bonds</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">A</th>
        <th colspan="2">C</th>
        <th colspan="2">G</th>
        <th colspan="2">T</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
            <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_whbond_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_whbond_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_whbond_between_#{aa}_and_rna", session[:redundancy], session[:resolution])%></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_whbond_between_amino_acids_and_#{rna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_rna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_rna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_whbond_between_amino_acids_and_rna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />


    <h4>c. Distribution of van der Waals contacts</h4>

    <table class="stats">
      <tr>
        <th rowspan="2"></th>
        <th colspan="2">A</th>
        <th colspan="2">C</th>
        <th colspan="2">G</th>
        <th colspan="2">T</th>
        <th colspan="2">Sugar</th>
        <th colspan="2">Phosphate</th>
        <th rowspan="2">Total</th>
      </tr>
      <tr>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
        <th>Obs</th>
        <th>Exp</th>
      </tr>
      <% Bipa::Constants::AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa| -%>
        <tr>
          <th><%= aa.upcase %></th>
          <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
            <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
            <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_#{rna}", session[:redundancy], session[:resolution]) %></td>
          <% end -%>
          <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_rna_sugar", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("observed_frequency_of_contact_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= "%.2f" % @scop.send("expected_frequency_of_contact_between_#{aa}_and_rna_phosphate", session[:redundancy], session[:resolution]) %></td>
          <td><%= @scop.send("total_observed_frequency_of_contact_between_#{aa}_and_rna", session[:redundancy], session[:resolution])%></td>
        </tr>
      <% end -%>
      <tr>
        <th>Total</th>
        <% Bipa::Constants::NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna| -%>
          <th colspan=2><%= @scop.send("total_observed_frequency_of_contact_between_amino_acids_and_#{rna}", session[:redundancy], session[:resolution]) %></th>
        <% end -%>
        <th colspan=2><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_rna_sugar(session[:redundancy], session[:resolution]) %></th>
        <th colspan=2><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_rna_phosphate(session[:redundancy], session[:resolution]) %></th>
        <th><%= @scop.total_observed_frequency_of_contact_between_amino_acids_and_rna(session[:redundancy], session[:resolution]) %></th>
      </tr>
    </table>
    <br />
  <% else %>
    N/A
  <% end %>
</div>
