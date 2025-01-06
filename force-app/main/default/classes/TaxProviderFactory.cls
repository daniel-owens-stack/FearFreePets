public with sharing class TaxProviderFactory {
    private static TaxProvider taxProvider;
    private static Map<String, TaxProvider> taxProviders = new Map<String, TaxProvider>();
   @testVisible
    private TaxProviderFactory() {
    }
    public static TaxProvider getTaxProvider(TaxMetaData taxMetaData) {
        System.debug('inside getTaxProvider taxMetaData'+taxMetaData);
        System.debug('inside getTaxProvider taxProviders'+taxProviders);
      if (taxProviders.containsKey(taxMetaData.providerImplClass)) {
        TaxProvider = taxProviders.get(taxMetaData.providerImplClass);
      } else {
        if (taxMetaData.providerImplClass != null) {
          Type t = Type.forName(taxMetaData.providerImplClass);
          TaxProvider = (TaxProvider) t.newInstance();
          TaxProviders.put(taxMetaData.providerImplClass, taxProvider);
        }
      }
        System.debug('taxProvider:::'+taxProvider);
      return taxProvider;
    }
  }